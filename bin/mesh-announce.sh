#!/usr/bin/env bash
# Push local session state to all fleet peers via SSH (fire-and-forget).
# Atomic local writes via tmp+mv. Remote writes are inherently atomic
# (single cat > file over SSH completes or fails).
set -uo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
mkdir -p "$STATE_DIR"

LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null || true)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

# Atomic local state write
SESSION_DATA="$(tmux list-sessions -F '#{session_name}|#{session_attached}|#{session_windows}' 2>/dev/null || true)"
_tmp="${STATE_DIR}/local.sessions.$$"
printf '%s\n' "$SESSION_DATA" > "$_tmp"
mv "$_tmp" "${STATE_DIR}/local.sessions"

# Refresh project index (background, non-blocking)
"${TMUXDESK_DIR}/bin/project-index.sh" 2>/dev/null &

PROJECT_DATA=""
[[ -f "${STATE_DIR}/local.projects" ]] && PROJECT_DATA="$(cat "${STATE_DIR}/local.projects")"

# Push to each peer
[[ -f "$FLEET_CONF" ]] || exit 0
while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  [[ "$name" == "$LOCAL_NAME" ]] && continue

  {
    ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$alias" \
      "mkdir -p ~/.tmux/tmuxdesk/state && cat > ~/.tmux/tmuxdesk/state/${LOCAL_NAME}.sessions" \
      <<< "$SESSION_DATA" 2>/dev/null || true

    if [[ -n "$PROJECT_DATA" ]]; then
      ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$alias" \
        "cat > ~/.tmux/tmuxdesk/state/${LOCAL_NAME}.projects" \
        <<< "$PROJECT_DATA" 2>/dev/null || true
    fi
  } &
done < "$FLEET_CONF"

disown -a 2>/dev/null
exit 0
