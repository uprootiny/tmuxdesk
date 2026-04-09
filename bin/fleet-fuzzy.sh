#!/usr/bin/env bash
# Fleet-wide fuzzy session finder — search sessions across all nodes
# Reads mesh state files + local sessions, presents in fzf, SSH-attaches on selection
set -euo pipefail

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf required for fleet-fuzzy"
  exit 1
fi

FLEET_CONF="${HOME}/.tmux/tmuxdesk/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null)"
[[ -z "$LOCAL_NAME" ]] && LOCAL_NAME="$(hostname -s)"

emit_rows() {
  # Local sessions (richer data)
  while IFS='|' read -r sname satt swins; do
    local mark=" "
    [[ "$satt" == "1" ]] && mark="*"
    printf '%s\tlocal\t%s\t%s %-20s  %sw  %s\n' \
      "$sname" "$LOCAL_NAME" "$mark" "$sname" "$swins" "(local)"
  done < <(tmux list-sessions -F '#{session_name}|#{session_attached}|#{session_windows}' 2>/dev/null)

  # Remote sessions from mesh state files
  while read -r name alias sigil ip; do
    [[ "$name" == "#"* || -z "$name" ]] && continue
    [[ "$name" == "$LOCAL_NAME" ]] && continue

    local state_file="${STATE_DIR}/${name}.sessions"
    [[ -f "$state_file" ]] || continue

    while IFS='|' read -r sname satt swins; do
      [[ -z "$sname" ]] && continue
      local mark=" "
      [[ "$satt" == "1" ]] && mark="*"
      printf '%s\tremote\t%s\t%s %-20s  %sw  %s %s\n' \
        "$sname" "$name" "$mark" "$sname" "$swins" "$sigil" "$name"
    done < "$state_file"
  done < "$FLEET_CONF"
}

selected="$(emit_rows | fzf \
  --delimiter='\t' \
  --with-nth=4 \
  --height=100% \
  --layout=reverse \
  --info=inline \
  --prompt='⊕ fleet session > ' \
  --header='* = attached  │  enter = switch/ssh  │  ctrl-c = cancel')"

[[ -z "$selected" ]] && exit 0

session_name="$(echo "$selected" | cut -f1)"
location="$(echo "$selected" | cut -f2)"
node="$(echo "$selected" | cut -f3)"

if [[ "$location" == "local" ]]; then
  tmux switch-client -t "$session_name" 2>/dev/null || \
    tmux attach -t "$session_name"
else
  # SSH to remote node and attach to the session
  ssh -t "$node" "tmux attach -t '$session_name' 2>/dev/null || tmux new-session -As '$session_name'"
fi
