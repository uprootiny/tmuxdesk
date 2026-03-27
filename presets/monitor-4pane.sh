#!/usr/bin/env bash
# monitor-4pane: tiled grid for monitoring dashboards
# Usage: monitor-4pane.sh [session] [cmd1] [cmd2] [cmd3] [cmd4]
set -euo pipefail
SESSION="${1:-monitor}"
CMD1="${2:-htop}"
CMD2="${3:-}"
CMD3="${4:-}"
CMD4="${5:-}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION"
tmux rename-window -t "$SESSION:1" "grid"
tmux split-window -t "$SESSION:1" -h
tmux split-window -t "$SESSION:1.1" -v
tmux split-window -t "$SESSION:1.3" -v
tmux select-layout -t "$SESSION:1" tiled

# Send commands to panes if provided
[[ -n "$CMD1" ]] && tmux send-keys -t "$SESSION:1.1" "$CMD1" Enter
[[ -n "$CMD2" ]] && tmux send-keys -t "$SESSION:1.2" "$CMD2" Enter
[[ -n "$CMD3" ]] && tmux send-keys -t "$SESSION:1.3" "$CMD3" Enter
[[ -n "$CMD4" ]] && tmux send-keys -t "$SESSION:1.4" "$CMD4" Enter

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
