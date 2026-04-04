#!/usr/bin/env bash
# Collect project activity index for the local node.
# Writes state/local.projects — one JSON line per project.
# Designed to run periodically (heartbeat, cron, or on-demand).
#
# Each line: {"name","path","host","sigil","last_commit_epoch","last_commit_age",
#             "commits_7d","files_changed_7d","branch","tmux_session","claude_sessions"}
set -uo pipefail

TMUXDESK_DIR="${HOME}/.tmux/tmuxdesk"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${TMUXDESK_DIR}/state"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$STATE_DIR"

# Resolve local identity
HOST_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$HOST_NAME" ]] && HOST_NAME="$(hostname -s)"
HOST_SIGIL=""

while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  if [[ "$name" == "$HOST_NAME" ]]; then
    HOST_SIGIL="$sigil"
    break
  fi
done < "$FLEET_CONF"

NOW=$(date +%s)
OUTPUT="${STATE_DIR}/local.projects"
TMP="${OUTPUT}.tmp.$$"

# --- Scan for git repos ---
# Search common locations; keep it fast with maxdepth
SEARCH_DIRS=("$HOME" "/opt" "/srv")
FOUND_REPOS=()

for base in "${SEARCH_DIRS[@]}"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r gitdir; do
    repo_dir="$(dirname "$gitdir")"
    FOUND_REPOS+=("$repo_dir")
  done < <(find "$base" -maxdepth 4 -name .git -type d 2>/dev/null | head -100)
done

# --- Active tmux sessions and their working directories ---
declare -A SESSION_DIRS
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
  while IFS='|' read -r sess_name pane_path; do
    SESSION_DIRS["$pane_path"]="${SESSION_DIRS[$pane_path]:-}${sess_name},"
  done < <(tmux list-panes -a -F '#{session_name}|#{pane_current_path}' 2>/dev/null || true)
fi

# --- Claude Code session index ---
# Map project directory slugs to session count
declare -A CLAUDE_COUNTS
if [[ -d "${CLAUDE_DIR}/projects" ]]; then
  for proj_dir in "${CLAUDE_DIR}/projects/"*; do
    [[ -d "$proj_dir" ]] || continue
    slug="$(basename "$proj_dir")"
    # Convert slug back to path: -Users-foo-bar → /Users/foo/bar
    real_path="/$(echo "$slug" | sed 's/^-//; s/-/\//g')"
    count=$(find "$proj_dir" -name '*.jsonl' -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$count" -gt 0 ]] && CLAUDE_COUNTS["$real_path"]="$count"
  done
fi

# --- Emit index ---
: > "$TMP"

for repo in "${FOUND_REPOS[@]}"; do
  [[ -d "$repo/.git" ]] || continue

  name="$(basename "$repo")"
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || echo "detached")"

  # Last commit
  last_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo "0")"
  last_age=$(( NOW - last_epoch ))

  # Activity in last 7 days
  commits_7d="$(git -C "$repo" rev-list --count --since="7 days ago" HEAD 2>/dev/null || echo "0")"
  files_7d="$(git -C "$repo" diff --stat "HEAD@{7 days ago}" HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo "0")"

  # Associated tmux session
  tmux_sess=""
  for dir in "${!SESSION_DIRS[@]}"; do
    if [[ "$dir" == "$repo"* ]]; then
      tmux_sess="${SESSION_DIRS[$dir]%,}"
      break
    fi
  done

  # Claude Code sessions
  claude_count="${CLAUDE_COUNTS[$repo]:-0}"

  # JSON line (no jq dependency — printf is fine for controlled data)
  printf '{"name":"%s","path":"%s","host":"%s","sigil":"%s","branch":"%s","last_commit_epoch":%s,"last_commit_age_s":%s,"commits_7d":%s,"files_changed_7d":%s,"tmux_session":"%s","claude_sessions":%s}\n' \
    "$name" "$repo" "$HOST_NAME" "$HOST_SIGIL" "$branch" \
    "$last_epoch" "$last_age" "$commits_7d" "$files_7d" \
    "$tmux_sess" "$claude_count" >> "$TMP"
done

mv "$TMP" "$OUTPUT"
