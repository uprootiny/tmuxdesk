#!/usr/bin/env bash
# Session-on-demand: switch to session if it exists, create if it doesn't
set -euo pipefail

SESSION_NAME="${1:-}"
[[ -z "$SESSION_NAME" ]] && exit 0

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux switch-client -t "$SESSION_NAME"
  tmux display-message "→ $SESSION_NAME"
else
  tmux new-session -d -s "$SESSION_NAME"
  tmux switch-client -t "$SESSION_NAME"
  tmux display-message "✦ $SESSION_NAME (new)"
fi
