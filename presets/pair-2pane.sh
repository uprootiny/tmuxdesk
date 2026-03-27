#!/usr/bin/env bash
# pair-2pane: side-by-side for pairing or diff work
set -euo pipefail
SESSION="${1:-pair}"
DIR="${2:-$HOME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$DIR"
tmux rename-window -t "$SESSION:1" "pair"
tmux split-window -t "$SESSION:1" -h -c "$DIR" -l 50%
tmux select-pane -t "$SESSION:1.1"

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
