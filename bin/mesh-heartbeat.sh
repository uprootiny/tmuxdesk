#!/usr/bin/env bash
set -uo pipefail
# Heartbeat: push local state and prune stale peer state files.
# Run via cron every 30s, systemd timer, or mesh-heartbeat-loop.sh.
#
# Threshold chain (must stay balanced):
#   push interval:  30s  — how often we announce
#   fresh window:   60s  — mesh-status.sh shows ● / ○
#   stale window:   120s — mesh-status.sh shows ◌ (2x push interval = 1 missed push)
#   dead threshold: 120s — mesh-status.sh shows ✕
#   prune after:    300s — delete state files (5min, avoids flicker on brief outages)
#
# Invariant: push_interval < fresh < stale < prune
#            30s          < 60s   < 120s  < 300s

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"

# Only run if tmux is active
tmux list-sessions &>/dev/null || exit 0

# Push state
"${TMUXDESK_DIR}/bin/mesh-announce.sh" 2>/dev/null || true

# Prune stale state files (>300s = 5 minutes)
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
PRUNE_THRESHOLD=300
NOW=$(date +%s)
for f in "${STATE_DIR}"/*.sessions "${STATE_DIR}"/*.projects; do
  [[ -f "$f" ]] || continue
  [[ "$(basename "$f")" == local.* ]] && continue
  if [[ "$(uname)" == "Darwin" ]]; then
    mod=$(stat -f '%m' "$f" 2>/dev/null || echo 0)
  else
    mod=$(stat -c '%Y' "$f" 2>/dev/null || echo 0)
  fi
  age=$(( NOW - mod ))
  (( age > PRUNE_THRESHOLD )) && rm -f "$f"
done
