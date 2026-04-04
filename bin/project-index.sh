#!/usr/bin/env bash
# Collect project activity index for the local node.
# Writes state/local.projects — one JSON line per project.
# Designed to run periodically (heartbeat, cron, or on-demand).
#
# Each line: {"name","path","host","sigil","last_commit_epoch","last_commit_age_s",
#             "commits_7d","files_changed_7d","branch","tmux_session","claude_sessions"}
set -euo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$STATE_DIR"

# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------
# Escape characters that break JSON strings: \ → \\, " → \"
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

json_obj() {
  # Emit a single JSON object. Args: key1 val1 type1 key2 val2 type2 ...
  # type: s = string, n = number
  local first=1
  printf '{'
  while (( $# >= 3 )); do
    (( first )) || printf ','
    first=0
    if [[ "$3" == "s" ]]; then
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
[[ -z "$HOST_NAME" ]] && HOST_NAME="$(hostname -s)"
HOST_SIGIL=""

if [[ -f "$FLEET_CONF" ]]; then
  while read -r name alias sigil ip; do
    [[ "$name" == "#"* || -z "$name" ]] && continue
    if [[ "$name" == "$HOST_NAME" ]]; then
      HOST_SIGIL="$sigil"
      break
    fi
  done < "$FLEET_CONF"
fi

NOW=$(date +%s)
OUTPUT="${STATE_DIR}/local.projects"
TMP="${OUTPUT}.tmp.$$"

# ---------------------------------------------------------------------------
# Scan for git repos (capped at 100 to keep runtime under 2s)
# ---------------------------------------------------------------------------
SEARCH_DIRS=("$HOME" "/opt" "/srv")
FOUND_REPOS=()

for base in "${SEARCH_DIRS[@]}"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r gitdir; do
    FOUND_REPOS+=("$(dirname "$gitdir")")
  done < <(find "$base" -maxdepth 4 -name .git -type d 2>/dev/null | head -100)
done

# ---------------------------------------------------------------------------
# Map tmux pane working dirs → session names
# ---------------------------------------------------------------------------
declare -A SESSION_DIRS
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
  while IFS='|' read -r sess_name pane_path; do
    SESSION_DIRS["$pane_path"]="${SESSION_DIRS[$pane_path]:-}${sess_name},"
  done < <(tmux list-panes -a -F '#{session_name}|#{pane_current_path}' 2>/dev/null || true)
fi

# ---------------------------------------------------------------------------
# Map Claude Code project slugs → session counts
# ---------------------------------------------------------------------------
declare -A CLAUDE_COUNTS
if [[ -d "${CLAUDE_DIR}/projects" ]]; then
  for proj_dir in "${CLAUDE_DIR}/projects/"*; do
    [[ -d "$proj_dir" ]] || continue
    slug="$(basename "$proj_dir")"
    # Slug format: -Users-foo-bar → /Users/foo/bar
    real_path="/$(printf '%s' "$slug" | sed 's/^-//; s/-/\//g')"
    count=$(find "$proj_dir" -name '*.jsonl' -type f 2>/dev/null | wc -l)
    count="${count##* }"  # trim leading whitespace (macOS wc)
    (( count > 0 )) && CLAUDE_COUNTS["$real_path"]="$count"
  done
fi

# ---------------------------------------------------------------------------
# Emit index — one JSON line per repo, atomic write via tmp+mv
# ---------------------------------------------------------------------------
: > "$TMP"

for repo in "${FOUND_REPOS[@]}"; do
  [[ -d "$repo/.git" ]] || continue

  repo_name="$(basename "$repo")"
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "detached")"

  last_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo "0")"
  last_age=$(( NOW - last_epoch ))

  # 7-day activity window
  commits_7d="$(git -C "$repo" rev-list --count --since="7 days ago" HEAD 2>/dev/null || echo "0")"
  files_7d="$(git -C "$repo" diff --stat "HEAD@{7 days ago}" HEAD 2>/dev/null \
    | tail -1 | sed -n 's/.*\([0-9][0-9]*\) file.*/\1/p')" || true
  files_7d="${files_7d:-0}"

  # Match tmux session by pane working directory
  tmux_sess=""
  for dir in "${!SESSION_DIRS[@]}"; do
    if [[ "$dir" == "$repo"* ]]; then
      tmux_sess="${SESSION_DIRS[$dir]%,}"
      break
    fi
  done

  claude_count="${CLAUDE_COUNTS[$repo]:-0}"

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
    tmux_session "$tmux_sess"   s \
    claude_sessions "$claude_count" n \
    >> "$TMP"
done

mv "$TMP" "$OUTPUT"
