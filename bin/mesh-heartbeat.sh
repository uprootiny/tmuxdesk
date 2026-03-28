#!/usr/bin/env bash
set -uo pipefail
# Heartbeat: push local state, prune stale peers
# Run via cron every 30s (or systemd timer)

# Only if tmux is running
tmux list-sessions &>/dev/null || exit 0

# Push state
"${HOME}/.tmux/tmuxdesk/bin/mesh-announce.sh" 2>/dev/null

# Prune stale state files (>600s)
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
NOW=$(date +%s)
for f in "${STATE_DIR}"/*.sessions; do
  [[ -f "$f" ]] || continue
  [[ "$(basename "$f")" == "local.sessions" ]] && continue
  if [[ "$(uname)" == "Darwin" ]]; then
    mod=$(stat -f '%m' "$f" 2>/dev/null || echo 0)
  else
    mod=$(stat -c '%Y' "$f" 2>/dev/null || echo 0)
  fi
  age=$(( NOW - mod ))
  (( age > 600 )) && rm -f "$f"
done
