#!/usr/bin/env bash
# Push local session state to all fleet peers via SSH (fire-and-forget)
set -uo pipefail

FLEET_CONF="${HOME}/.tmux/tmuxdesk/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
mkdir -p "$STATE_DIR"

# Get local hostname from tmux config
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

# Dump local session state
SESSION_DATA="$(tmux list-sessions -F '#{session_name}|#{session_attached}|#{session_windows}' 2>/dev/null || true)"
echo "$SESSION_DATA" > "${STATE_DIR}/local.sessions"

# Refresh project index (background, non-blocking)
"${HOME}/.tmux/tmuxdesk/bin/project-index.sh" 2>/dev/null &

PROJECT_DATA=""
[[ -f "${STATE_DIR}/local.projects" ]] && PROJECT_DATA="$(cat "${STATE_DIR}/local.projects")"

# Push to each peer
while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  [[ "$name" == "$LOCAL_NAME" ]] && continue

  {
    ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$alias" \
      "mkdir -p ~/.tmux/tmuxdesk/state && cat > ~/.tmux/tmuxdesk/state/${LOCAL_NAME}.sessions" \
      <<< "$SESSION_DATA" 2>/dev/null

    if [[ -n "$PROJECT_DATA" ]]; then
      ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$alias" \
        "cat > ~/.tmux/tmuxdesk/state/${LOCAL_NAME}.projects" \
        <<< "$PROJECT_DATA" 2>/dev/null
    fi
  } &
done < "$FLEET_CONF"

# Don't wait — fire and forget
disown -a 2>/dev/null
exit 0
