#!/usr/bin/env bash
# Render fleet mesh status for tmux status-right (pure local file reads, no SSH)
# Output: 🜂●3∴●2☰○1∞✕∇●1  (compact: sigil + state + count, no spaces)
#
# State indicators:
#   ● = online, at least one attached session
#   ○ = online, no attached sessions
#   ◌ = stale data (60-120s old) — showing last known count but flagged
#   ✕ = offline / state file missing or older than 120s
#
# Local node is always read live from `tmux list-sessions`.
# Designed to run every 5s in status-interval; must complete < 100ms.
set -uo pipefail
# Note: no -e here — this runs in status-interval and must never abort mid-render

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"

[[ -f "$FLEET_CONF" ]] || { printf '?'; exit 0; }
mkdir -p "$STATE_DIR"

# Determine local hostname — prefer tmux variable, fall back to hostname -s
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

NOW="$(date +%s)"

# Staleness thresholds (seconds) — balanced against heartbeat interval:
#   heartbeat pushes every 30s → 1 missed push = 60s (warn)
#   2 missed pushes = 120s → node is likely down (dead)
#   see mesh-heartbeat.sh for the full threshold chain
STALE_WARN=60    # 60-120s: show ◌ (stale-but-recent, 1 missed heartbeat)
STALE_DEAD=120   # >120s: show ✕ (offline, 2+ missed heartbeats)

output=""

while read -r name alias sigil ip; do
  # Skip comments and blank lines
  [[ "$name" == "#"* || -z "$name" ]] && continue

  # --- Local node: read live from tmux, never from state file ---
  if [[ "$name" == "$LOCAL_NAME" ]]; then
    sessions="$(tmux list-sessions -F '#{session_name}|#{session_attached}|#{session_windows}' 2>/dev/null)" || true
    if [[ -z "$sessions" ]]; then
      output+="${sigil}○0"
      continue
    fi
    total="$(printf '%s\n' "$sessions" | grep -c '.' || true)"
    attached="$(printf '%s\n' "$sessions" | grep -c '|1|' || true)"
    if (( attached > 0 )); then
      output+="${sigil}●${total}"
    else
      output+="${sigil}○${total}"
    fi
    continue
  fi

  # --- Remote node: read from state file ---
  state_file="${STATE_DIR}/${name}.sessions"

  if [[ ! -f "$state_file" ]]; then
    output+="${sigil}✕"
    continue
  fi

  # Compute file age (portable: macOS vs Linux stat)
  if [[ "$(uname)" == "Darwin" ]]; then
    age=$(( NOW - $(stat -f %m "$state_file") ))
  else
    age=$(( NOW - $(stat -c %Y "$state_file") ))
  fi

  # Completely stale — treat as offline
  if (( age > STALE_DEAD )); then
    output+="${sigil}✕"
    continue
  fi

  # Parse session data from state file
  sessions="$(cat "$state_file" 2>/dev/null)"
  if [[ -z "$sessions" ]]; then
    # File exists but empty — node is up with no sessions
    if (( age > STALE_WARN )); then
      output+="${sigil}◌0"
    else
      output+="${sigil}·"
    fi
    continue
  fi

  total="$(printf '%s\n' "$sessions" | grep -c '.' || true)"
  attached="$(printf '%s\n' "$sessions" | grep -c '|1|' || true)"

  # Stale-but-recent (60-120s): show last known count with ◌
  if (( age > STALE_WARN )); then
    output+="${sigil}◌${total}"
    continue
  fi

  # Fresh data — normal indicators
  if (( attached > 0 )); then
    output+="${sigil}●${total}"
  else
    output+="${sigil}○${total}"
  fi
done < "$FLEET_CONF"

printf '%s' "$output"
