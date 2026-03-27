#!/usr/bin/env bash
# dev-3pane: main-vertical layout — large editor pane + terminal + logs/repl
set -euo pipefail
SESSION="${1:-dev}"
DIR="${2:-$HOME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$DIR"
tmux rename-window -t "$SESSION:1" "edit"
tmux split-window -t "$SESSION:1" -h -c "$DIR" -l 40%
tmux split-window -t "$SESSION:1.2" -v -c "$DIR" -l 50%
tmux select-pane -t "$SESSION:1.1"
tmux select-layout -t "$SESSION:1" main-vertical

# Hint the user
tmux send-keys -t "$SESSION:1.1" "# editor pane" Enter
tmux send-keys -t "$SESSION:1.2" "# terminal" Enter
tmux send-keys -t "$SESSION:1.3" "# logs / repl" Enter

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
