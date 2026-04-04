#!/usr/bin/env bash
# Fleet-wide project search — fuzzy find across all nodes.
# Reads state/*.projects files (propagated by mesh) and local.projects.
# Launched via Prefix+G in tmux.
#
# Display format per line:
#   sigil name [branch] 3c/7d 12f host:/path ●session 🤖2
#                        │      │             │         └ claude sessions
#                        │      │             └ tmux session (if active)
#                        │      └ files changed in 7d
#                        └ commits in 7d
set -uo pipefail

TMUXDESK_DIR="${HOME}/.tmux/tmuxdesk"
STATE_DIR="${TMUXDESK_DIR}/state"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"

# Determine local host
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

# Refresh local index first (fast, <1s)
"${TMUXDESK_DIR}/bin/project-index.sh" 2>/dev/null &

# Collect all project lines from state files
ALL_LINES=""

for f in "${STATE_DIR}"/*.projects; do
  [[ -f "$f" ]] || continue
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ALL_LINES+="${line}"$'\n'
  done < "$f"
done

# Wait for local refresh
wait 2>/dev/null

# Include fresh local data
if [[ -f "${STATE_DIR}/local.projects" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ALL_LINES+="${line}"$'\n'
  done < "${STATE_DIR}/local.projects"
fi

if [[ -z "$ALL_LINES" ]]; then
  echo "no projects indexed yet"
  exit 0
fi

# Format for fzf display
format_line() {
  local line="$1"
  # Parse JSON-ish with bash (no jq dependency)
  local name sigil branch commits_7d files_7d host path tmux_sess claude_count
  name="$(echo "$line"   | grep -oP '"name":"\K[^"]*')"
  sigil="$(echo "$line"  | grep -oP '"sigil":"\K[^"]*')"
  branch="$(echo "$line" | grep -oP '"branch":"\K[^"]*')"
  commits_7d="$(echo "$line" | grep -oP '"commits_7d":\K[0-9]*')"
  files_7d="$(echo "$line"   | grep -oP '"files_changed_7d":\K[0-9]*')"
  host="$(echo "$line"   | grep -oP '"host":"\K[^"]*')"
  path="$(echo "$line"   | grep -oP '"path":"\K[^"]*')"
  tmux_sess="$(echo "$line"  | grep -oP '"tmux_session":"\K[^"]*')"
  claude_count="$(echo "$line" | grep -oP '"claude_sessions":\K[0-9]*')"
  last_age="$(echo "$line" | grep -oP '"last_commit_age_s":\K[0-9]*')"

  # Human-readable age
  local age_str=""
  if [[ -n "$last_age" && "$last_age" -gt 0 ]]; then
    if (( last_age < 3600 )); then
      age_str="$(( last_age / 60 ))m"
    elif (( last_age < 86400 )); then
      age_str="$(( last_age / 3600 ))h"
    else
      age_str="$(( last_age / 86400 ))d"
    fi
  fi

  # Activity indicator
  local activity=""
  if [[ "$commits_7d" -gt 0 ]]; then
    activity="${commits_7d}c/${files_7d}f"
  else
    activity="quiet"
  fi

  # Build display line
  local display="${sigil} ${name}"
  [[ -n "$branch" && "$branch" != "main" && "$branch" != "master" ]] && display+=" [${branch}]"
  display+="  ${activity}  ${age_str}"
  display+="  ${host}:${path}"
  [[ -n "$tmux_sess" ]] && display+="  ●${tmux_sess}"
  [[ "$claude_count" -gt 0 ]] && display+="  cc:${claude_count}"

  printf '%s\t%s\t%s\n' "$display" "$host" "$path"
}

# Build fzf input
FZF_INPUT=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  FZF_INPUT+="$(format_line "$line")"$'\n'
done <<< "$ALL_LINES"

# Sort: most recently active first (by age field in display)
FZF_INPUT="$(echo "$FZF_INPUT" | sort -t$'\t' -k1,1)"

if ! command -v fzf >/dev/null 2>&1; then
  # Fallback: just print
  echo "$FZF_INPUT" | cut -f1
  exit 0
fi

PICK="$(echo "$FZF_INPUT" | \
  fzf --with-nth=1 \
      --delimiter=$'\t' \
      --prompt="fleet project> " \
      --header="enter=ssh to project  ctrl-s=open session  ctrl-c=claude history" \
      --height=80% \
      --reverse \
      --ansi \
      --bind="ctrl-r:reload(${TMUXDESK_DIR}/bin/fleet-search.sh --raw)" \
      --expect="enter,ctrl-s,ctrl-c"
)"

[[ -z "$PICK" ]] && exit 0

KEY="$(echo "$PICK" | head -1)"
SELECTED="$(echo "$PICK" | tail -1)"
SEL_HOST="$(echo "$SELECTED" | cut -f2)"
SEL_PATH="$(echo "$SELECTED" | cut -f3)"

case "$KEY" in
  enter)
    # SSH to the project directory (or cd if local)
    if [[ "$SEL_HOST" == "$LOCAL_NAME" ]]; then
      tmux send-keys "cd '$SEL_PATH'" Enter
    else
      tmux new-window -n "$(basename "$SEL_PATH")" "ssh -t $SEL_HOST 'cd $SEL_PATH && exec \$SHELL -l'"
    fi
    ;;
  ctrl-s)
    # Attach to tmux session on that host
    tmux_sess="$(echo "$SELECTED" | grep -oP '●\K[^ ]*')"
    if [[ -n "$tmux_sess" ]]; then
      if [[ "$SEL_HOST" == "$LOCAL_NAME" ]]; then
        tmux switch-client -t "$tmux_sess"
      else
        tmux new-window -n "$tmux_sess" "ssh -t $SEL_HOST 'tmux attach -t $tmux_sess'"
      fi
    fi
    ;;
  ctrl-c)
    # Show Claude Code session history for this project
    slug="$(echo "$SEL_PATH" | sed 's|^/||; s|/|-|g')"
    claude_dir="${HOME}/.claude/projects/-${slug}"
    if [[ -d "$claude_dir" ]]; then
      # List sessions with timestamps
      find "$claude_dir" -name '*.jsonl' -type f -exec stat -f '%m %N' {} \; 2>/dev/null | \
        sort -rn | \
        while read -r epoch file; do
          ts="$(date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null)"
          echo "$ts  $(basename "$file")"
        done | \
        fzf --prompt="claude sessions for $(basename "$SEL_PATH")> " --height=50% --reverse
    else
      echo "no claude sessions found for $SEL_PATH"
      sleep 2
    fi
    ;;
esac
