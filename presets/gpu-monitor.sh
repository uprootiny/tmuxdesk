#!/usr/bin/env bash
# gpu-monitor: GPU and compute monitoring session (host: finml)
# 4-pane tiled grid for nvidia-smi/htop/disk/shell + logs window
set -euo pipefail
SESSION="${1:-gpumon}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION"
tmux rename-window -t "$SESSION:1" "gpu"

# Build 4-pane tiled grid
tmux split-window -t "$SESSION:1" -h
tmux split-window -t "$SESSION:1.1" -v
tmux split-window -t "$SESSION:1.3" -v
tmux select-layout -t "$SESSION:1" tiled

# Pane 1: nvidia-smi with htop fallback
tmux send-keys -t "$SESSION:1.1" \
  'if command -v nvidia-smi >/dev/null 2>&1; then watch -n 1 nvidia-smi; else htop; fi' Enter

# Pane 2: htop
tmux send-keys -t "$SESSION:1.2" 'htop' Enter

# Pane 3: disk usage
tmux send-keys -t "$SESSION:1.3" \
  "watch -n 5 'df -h / /data 2>/dev/null || df -h /'" Enter

# Pane 4: ad-hoc shell (no command)

# Window 2: logs
tmux new-window -t "$SESSION" -n "logs"
tmux send-keys -t "$SESSION:2" \
  'tail -f /var/log/syslog 2>/dev/null || journalctl -f' Enter

# Focus first window
tmux select-window -t "$SESSION:1"

if [ "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
