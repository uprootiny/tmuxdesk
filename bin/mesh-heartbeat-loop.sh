#!/usr/bin/env bash
# Heartbeat loop for systems without cron/systemd timers.
# Runs mesh-heartbeat.sh every 30s while tmux is alive.
# Interval matches the cron recommendation and stays under the 60s fresh window.
set -uo pipefail
TMUXDESK_DIR="${TMUXDESK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INTERVAL=30  # must be < STALE_WARN (60s) to avoid false stale indicators
while tmux list-sessions &>/dev/null; do
  "${TMUXDESK_DIR}/bin/mesh-heartbeat.sh" 2>/dev/null || true
  sleep "$INTERVAL"
done
