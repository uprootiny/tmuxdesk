#!/usr/bin/env bash
# Collect project activity index for the local node.
# Writes state/local.projects — one JSON line per project.
# Designed to run periodically (heartbeat, cron, or on-demand).
#
# Each line: {"name","path","host","sigil","last_commit_epoch","last_commit_age_s",
#             "commits_7d","files_changed_7d","branch","tmux_session","claude_sessions"}
#
# Portable: bash 3+, no associative arrays, no GNU-only tools.
set -euo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$STATE_DIR"

# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

json_obj() {
  local first=1
  printf '{'
  while [ $# -ge 3 ]; do
    [ "$first" -eq 1 ] || printf ','
    first=0
    if [ "$3" = "s" ]; then
      printf '"%s":"%s"' "$1" "$(json_escape "$2")"
    else
      printf '"%s":%s' "$1" "${2:-0}"
    fi
    shift 3
  done
  printf '}\n'
}

# ---------------------------------------------------------------------------
# Resolve local identity
# ---------------------------------------------------------------------------
HOST_NAME="$(tmux show -gqv @host_name 2>/dev/null || true)"
[ -z "$HOST_NAME" ] && HOST_NAME="$(hostname -s)"
HOST_SIGIL=""

if [ -f "$FLEET_CONF" ]; then
  while read -r name alias sigil ip; do
    case "$name" in "#"*|"") continue ;; esac
    if [ "$name" = "$HOST_NAME" ]; then
      HOST_SIGIL="$sigil"
      break
    fi
  done < "$FLEET_CONF"
fi

NOW=$(date +%s)
OUTPUT="${STATE_DIR}/local.projects"
TMP="${OUTPUT}.tmp.$$"

# ---------------------------------------------------------------------------
# Scan for git repos
# Prune heavy dirs (node_modules, .nix, venv, .cache) to keep find fast.
# Capped at 100 results.
# ---------------------------------------------------------------------------
SEARCH_DIRS="$HOME /opt /srv"
FOUND_REPOS=""

for base in $SEARCH_DIRS; do
  [ -d "$base" ] || continue
  results="$(find "$base" -maxdepth 4 -name .git -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.nix-*" \
    -not -path "*/venv/*" \
    -not -path "*/.cache/*" \
    -not -path "*/.cargo/*" \
    -not -path "*/target/*" \
    2>/dev/null | head -100)"
  for gitdir in $results; do
    FOUND_REPOS="${FOUND_REPOS}$(dirname "$gitdir")"$'\n'
  done
done

# ---------------------------------------------------------------------------
# Collect tmux pane working dirs → session names (portable, no declare -A)
# Format: path|session1,session2
# ---------------------------------------------------------------------------
TMUX_PANE_MAP=""
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
  TMUX_PANE_MAP="$(tmux list-panes -a -F '#{pane_current_path}|#{session_name}' 2>/dev/null || true)"
fi

# Lookup: find tmux session for a repo path
tmux_session_for() {
  local repo="$1"
  [ -z "$TMUX_PANE_MAP" ] && return
  printf '%s\n' "$TMUX_PANE_MAP" | while IFS='|' read -r pane_path sess_name; do
    case "$pane_path" in "$repo"*)
      printf '%s' "$sess_name"
      return
      ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Count Claude Code sessions for a path (portable, no declare -A)
# ---------------------------------------------------------------------------
claude_count_for() {
  local repo="$1"
  local slug
  slug="$(printf '%s' "$repo" | sed 's|^/||; s|/|-|g')"
  local proj_dir="${CLAUDE_DIR}/projects/-${slug}"
  if [ -d "$proj_dir" ]; then
    local c
    c=$(find "$proj_dir" -name '*.jsonl' -type f 2>/dev/null | wc -l)
    printf '%s' "${c##* }"  # trim whitespace (macOS wc)
  else
    printf '0'
  fi
}

# ---------------------------------------------------------------------------
# Emit index — one JSON line per repo, atomic write via tmp+mv
# ---------------------------------------------------------------------------
: > "$TMP"

printf '%s\n' "$FOUND_REPOS" | while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  [ -d "$repo/.git" ] || continue

  repo_name="$(basename "$repo")"
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "detached")"

  last_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo "0")"
  last_age=$(( NOW - last_epoch ))

  commits_7d="$(git -C "$repo" rev-list --count --since="7 days ago" HEAD 2>/dev/null || echo "0")"
  files_7d="$(git -C "$repo" diff --stat "HEAD@{7 days ago}" HEAD 2>/dev/null \
    | tail -1 | sed -n 's/.*\([0-9][0-9]*\) file.*/\1/p')" || true
  files_7d="${files_7d:-0}"

  tmux_sess="$(tmux_session_for "$repo")"
  claude_count="$(claude_count_for "$repo")"

  json_obj \
    name        "$repo_name"    s \
    path        "$repo"         s \
    host        "$HOST_NAME"    s \
    sigil       "$HOST_SIGIL"   s \
    branch      "$branch"       s \
    last_commit_epoch "$last_epoch" n \
    last_commit_age_s "$last_age"   n \
    commits_7d  "$commits_7d"   n \
    files_changed_7d "$files_7d" n \
    tmux_session "${tmux_sess:-}" s \
    claude_sessions "${claude_count:-0}" n \
    >> "$TMP"
done

mv "$TMP" "$OUTPUT"
