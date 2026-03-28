#!/usr/bin/env bash
# Simple heartbeat loop for systems without cron (e.g., NixOS)
# Started by tmux; exits when tmux dies
set -uo pipefail
SCRIPT="${HOME}/.tmux/tmuxdesk/bin/mesh-heartbeat.sh"
while tmux list-sessions &>/dev/null; do
  "$SCRIPT" 2>/dev/null
  sleep 60
done
