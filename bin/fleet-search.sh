#!/usr/bin/env bash
# Fleet-wide project search — fuzzy find across all nodes.
# Reads state/*.projects files (propagated by mesh) and local.projects.
# Launched via Prefix+G in tmux.
#
# Display format per line:
#   sigil name [branch] 3c/7d 12f host:/path ●session cc:2
set -euo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"

mkdir -p "$STATE_DIR"

# ---------------------------------------------------------------------------
# Portable JSON field extraction (no grep -P, no jq)
# Usage: json_str <json_line> <field_name>  → value (string fields)
#        json_num <json_line> <field_name>  → value (numeric fields)
# ---------------------------------------------------------------------------
json_str() { printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
json_num() { printf '%s' "$1" | sed -n "s/.*\"$2\":\([0-9]*\).*/\1/p"; }

# ---------------------------------------------------------------------------
# Determine local host
# ---------------------------------------------------------------------------
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null || true)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

# Refresh local index (fast, <1s, background)
"${TMUXDESK_DIR}/bin/project-index.sh" 2>/dev/null &

# ---------------------------------------------------------------------------
# Collect all project lines from state files
# ---------------------------------------------------------------------------
ALL_LINES=""

for f in "${STATE_DIR}"/*.projects; do
  [[ -f "$f" ]] || continue
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ALL_LINES+="${line}"$'\n'
  done < "$f"
done

wait 2>/dev/null || true

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

# ---------------------------------------------------------------------------
# Format a JSON line into a display string for fzf
# ---------------------------------------------------------------------------
format_line() {
  local line="$1"
  local name sigil branch commits_7d files_7d host path tmux_sess claude_count last_age

  name="$(json_str "$line" name)"
  sigil="$(json_str "$line" sigil)"
  branch="$(json_str "$line" branch)"
  commits_7d="$(json_num "$line" commits_7d)"
  files_7d="$(json_num "$line" files_changed_7d)"
  host="$(json_str "$line" host)"
  path="$(json_str "$line" path)"
  tmux_sess="$(json_str "$line" tmux_session)"
  claude_count="$(json_num "$line" claude_sessions)"
  last_age="$(json_num "$line" last_commit_age_s)"

  # Defaults for missing values
  commits_7d="${commits_7d:-0}"
  files_7d="${files_7d:-0}"
  claude_count="${claude_count:-0}"
  last_age="${last_age:-0}"

  # Human-readable age
  local age_str=""
  if (( last_age > 0 )); then
    if (( last_age < 3600 )); then
      age_str="$(( last_age / 60 ))m"
    elif (( last_age < 86400 )); then
      age_str="$(( last_age / 3600 ))h"
    else
      age_str="$(( last_age / 86400 ))d"
    fi
  fi

  # Activity indicator
  local activity="quiet"
  if (( commits_7d > 0 )); then
    activity="${commits_7d}c/${files_7d}f"
  fi

  # Build display
  local display="${sigil} ${name}"
  [[ -n "$branch" && "$branch" != "main" && "$branch" != "master" ]] && display+=" [${branch}]"
  display+="  ${activity}  ${age_str}"
  display+="  ${host}:${path}"
  [[ -n "$tmux_sess" ]] && display+="  ●${tmux_sess}"
  (( claude_count > 0 )) && display+="  cc:${claude_count}"

  printf '%s\t%s\t%s\t%s\n' "$display" "$host" "$path" "$tmux_sess"
}

# ---------------------------------------------------------------------------
# Build fzf input
# ---------------------------------------------------------------------------
FZF_INPUT=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  FZF_INPUT+="$(format_line "$line")"$'\n'
done <<< "$ALL_LINES"

FZF_INPUT="$(printf '%s' "$FZF_INPUT" | sort -t$'\t' -k1,1)"

if ! command -v fzf >/dev/null 2>&1; then
  printf '%s\n' "$FZF_INPUT" | cut -f1
  exit 0
fi

# ---------------------------------------------------------------------------
# fzf selection
# ---------------------------------------------------------------------------
PICK="$(printf '%s\n' "$FZF_INPUT" | \
  fzf --with-nth=1 \
      --delimiter=$'\t' \
      --prompt="fleet project> " \
      --header="enter=ssh to project  ctrl-s=open session  ctrl-c=claude history" \
      --height=80% \
      --reverse \
      --ansi \
      --expect="enter,ctrl-s,ctrl-c"
)" || exit 0

[[ -z "$PICK" ]] && exit 0

KEY="$(printf '%s' "$PICK" | head -1)"
SELECTED="$(printf '%s' "$PICK" | tail -1)"
SEL_HOST="$(printf '%s' "$SELECTED" | cut -f2)"
SEL_PATH="$(printf '%s' "$SELECTED" | cut -f3)"
SEL_SESS="$(printf '%s' "$SELECTED" | cut -f4)"

case "$KEY" in
  enter)
    if [[ "$SEL_HOST" == "$LOCAL_NAME" ]]; then
      tmux send-keys "cd '$(printf '%s' "$SEL_PATH" | sed "s/'/'\\\\''/g")'" Enter
    else
      tmux new-window -n "$(basename "$SEL_PATH")" \
        "ssh -t '${SEL_HOST}' 'cd \"${SEL_PATH}\" && exec \$SHELL -l'"
    fi
    ;;
  ctrl-s)
    if [[ -n "$SEL_SESS" ]]; then
      if [[ "$SEL_HOST" == "$LOCAL_NAME" ]]; then
        tmux switch-client -t "$SEL_SESS"
      else
        tmux new-window -n "$SEL_SESS" \
          "ssh -t '${SEL_HOST}' 'tmux attach -t \"${SEL_SESS}\"'"
      fi
    fi
    ;;
  ctrl-c)
    slug="$(printf '%s' "$SEL_PATH" | sed 's|^/||; s|/|-|g')"
    claude_dir="${HOME}/.claude/projects/-${slug}"
    if [[ -d "$claude_dir" ]]; then
      # Portable stat: macOS vs Linux
      if [[ "$(uname)" == "Darwin" ]]; then
        find "$claude_dir" -name '*.jsonl' -type f -exec stat -f '%m %N' {} \; 2>/dev/null
      else
        find "$claude_dir" -name '*.jsonl' -type f -exec stat -c '%Y %n' {} \; 2>/dev/null
      fi | sort -rn | \
        while read -r epoch file; do
          if [[ "$(uname)" == "Darwin" ]]; then
            ts="$(date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$epoch")"
          else
            ts="$(date -d "@$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$epoch")"
          fi
          echo "$ts  $(basename "$file")"
        done | \
        fzf --prompt="claude sessions for $(basename "$SEL_PATH")> " --height=50% --reverse || true
    else
      echo "no claude sessions found for $SEL_PATH"
      sleep 2
    fi
    ;;
esac
