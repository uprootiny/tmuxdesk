#!/usr/bin/env bash
# nix-workshop: NixOS configuration session (host: karlsruhe)
# config editing + build + store inspection
set -euo pipefail
SESSION="${1:-nix}"
NIX_DIR="/etc/nixos"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

# Resolve working directory
if [ -d "$NIX_DIR" ]; then
  WORK_DIR="$NIX_DIR"
else
  WORK_DIR="$HOME"
fi

tmux new-session -d -s "$SESSION" -c "$WORK_DIR"
tmux rename-window -t "$SESSION:1" "config"

# 2 vertical panes for config editing
tmux split-window -t "$SESSION:1" -h -c "$WORK_DIR"
tmux select-pane -t "$SESSION:1.1"

# Window 2: build
tmux new-window -t "$SESSION" -n "build" -c "$WORK_DIR"

# Window 3: store inspection
tmux new-window -t "$SESSION" -n "store"
tmux send-keys -t "$SESSION:3" 'nix store info' Enter

# Focus first window
tmux select-window -t "$SESSION:1"

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
