#!/usr/bin/env bash
# Render fleet mesh status for status-right (pure local file reads, no SSH)
# Output: ∴●2 ☰○1 ∞✕  (sigil, state dot, session count per peer)
# Also triggers heartbeat re-announce every 90s to keep quiet nodes visible.
set -uo pipefail

FLEET_CONF="${HOME}/.tmux/tmuxdesk/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

# --- Heartbeat: re-announce every 90s ---
HEARTBEAT_FILE="${STATE_DIR}/.last_heartbeat"
now="$(date +%s)"
last_beat=0
[[ -f "$HEARTBEAT_FILE" ]] && last_beat="$(cat "$HEARTBEAT_FILE" 2>/dev/null)"
if (( now - last_beat > 90 )); then
  echo "$now" > "$HEARTBEAT_FILE"
  "${HOME}/.tmux/tmuxdesk/bin/mesh-announce.sh" &>/dev/null &
  disown 2>/dev/null
fi

output=""

while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  [[ "$name" == "$LOCAL_NAME" ]] && continue

  state_file="${STATE_DIR}/${name}.sessions"

  if [[ ! -f "$state_file" ]]; then
    output+="${sigil}✕ "
    continue
  fi

  # Check staleness
  age=0
  if [[ "$(uname)" == "Darwin" ]]; then
    age=$(( $(date +%s) - $(stat -f %m "$state_file") ))
  else
    age=$(( $(date +%s) - $(stat -c %Y "$state_file") ))
  fi

  if (( age > 300 )); then
    output+="${sigil}✕ "
    continue
  fi

  # Parse session state
  sessions="$(cat "$state_file" 2>/dev/null)"
  if [[ -z "$sessions" ]]; then
    output+="${sigil}· "
    continue
  fi

  total="$(echo "$sessions" | grep -c '.' || true)"
  attached="$(echo "$sessions" | grep -c '|1|' || true)"

  if (( attached > 0 )); then
    output+="${sigil}●${total} "
  else
    output+="${sigil}○${total} "
  fi
done < "$FLEET_CONF"

# Trim trailing space
printf '%s' "${output% }"
