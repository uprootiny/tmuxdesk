#!/usr/bin/env bash
# agent-orchestra: parallel AI agent session (host: hyle)
# 3 vertical panes for claude / codex / gemini + scratch window
set -euo pipefail
SESSION="${1:-agents}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION"
tmux rename-window -t "$SESSION:1" "orchestra"

# 3 vertical panes side by side
tmux split-window -t "$SESSION:1" -h
tmux split-window -t "$SESSION:1" -h
tmux select-layout -t "$SESSION:1" even-horizontal

# Label each pane
tmux send-keys -t "$SESSION:1.1" '# ── claude ──' Enter 'clear' Enter
tmux send-keys -t "$SESSION:1.2" '# ── codex ──' Enter 'clear' Enter
tmux send-keys -t "$SESSION:1.3" '# ── gemini ──' Enter 'clear' Enter

tmux select-pane -t "$SESSION:1.1"

# Window 2: scratch
tmux new-window -t "$SESSION" -n "scratch"

# Focus first window
tmux select-window -t "$SESSION:1"

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
