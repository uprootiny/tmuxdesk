#!/usr/bin/env bash
# Interactive session picker for a fleet node — use as iTerm profile command
# Usage: session-picker.sh <ssh_alias>
set -euo pipefail

HOST="${1:?usage: session-picker.sh <ssh_alias>}"

SESSIONS=$(ssh -o ConnectTimeout=3 "$HOST" 'tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_windows}" 2>/dev/null' || true)

if [[ -z "$SESSIONS" ]]; then
  echo "no sessions on $HOST — creating 'main'"
  exec ssh -t "$HOST" 'tmux -CC new -s main'
fi

if command -v fzf >/dev/null 2>&1; then
  PICK=$(echo "$SESSIONS" | while IFS='|' read -r name att wins; do
    state="○"
    [[ "$att" == "1" ]] && state="●"
    printf "%s %s %dw\n" "$state" "$name" "$wins"
  done | fzf --prompt="$HOST session> " --height=40% --reverse | awk '{print $2}')
else
  echo "sessions on $HOST:"
  i=1
  while IFS='|' read -r name att wins; do
    state="○"
    [[ "$att" == "1" ]] && state="●"
    printf "  %d) %s %s (%d windows)\n" "$i" "$state" "$name" "$wins"
    i=$((i + 1))
  done <<< "$SESSIONS"
  printf "pick [1]: "
  read -r choice
  choice="${choice:-1}"
  PICK=$(echo "$SESSIONS" | sed -n "${choice}p" | cut -d'|' -f1)
fi

if [[ -n "${PICK:-}" ]]; then
  exec ssh -t "$HOST" "tmux -CC new -A -s '$PICK'"
else
  echo "cancelled"
fi
