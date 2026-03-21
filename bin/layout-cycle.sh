#!/usr/bin/env bash
# Cycle through tmux layouts for the current window
# Uses per-window state so cycling in one window doesn't affect others
set -euo pipefail

direction="${1:-next}"
layouts=(tiled even-horizontal even-vertical main-horizontal main-vertical)
count="${#layouts[@]}"

# Per-window key: @layout_idx_<session>_<window>
session="$(tmux display-message -p '#S')"
window="$(tmux display-message -p '#I')"
key="@layout_idx_${session}_${window}"

cur="$(tmux show -gqv "$key" || true)"
if [[ -z "${cur}" || ! "${cur}" =~ ^[0-9]+$ ]]; then
  cur=0
fi

if [[ "${direction}" == "prev" ]]; then
  next=$(( (cur - 1 + count) % count ))
else
  next=$(( (cur + 1) % count ))
fi

layout="${layouts[$next]}"
tmux select-layout "${layout}"
tmux set -gq "$key" "${next}"
tmux display-message "⊞ ${layout} [$(( next + 1 ))/${count}]"
