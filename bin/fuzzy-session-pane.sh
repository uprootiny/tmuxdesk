#!/usr/bin/env bash
set -euo pipefail

if ! command -v fzf >/dev/null 2>&1; then
  tmux choose-tree -Zw
  exit 0
fi

TMUXDESK="${HOME}/.tmux/tmuxdesk"

format_age() {
  local created now delta d h m
  created="${1:-0}"
  now="$(date +%s)"
  delta=$(( now - created ))
  (( delta < 0 )) && delta=0
  d=$(( delta / 86400 ))
  h=$(( (delta % 86400) / 3600 ))
  m=$(( (delta % 3600) / 60 ))
  if (( d > 0 )); then
    printf '%dd%dh' "$d" "$h"
    return
  fi
  if (( h > 0 )); then
    printf '%dh%dm' "$h" "$m"
    return
  fi
  printf '%dm' "$m"
}

emit_rows() {
  local host
  host="$(tmux display-message -p '#H')"

  while IFS='|' read -r sname swins satt screated; do
    local mark age
    mark=" "
    [[ "$satt" == "1" ]] && mark="*"
    age="$(format_age "$screated")"
    printf 'session\t%s\t%s session %-16s age:%-7s host:%s windows:%s\n' \
      "$sname" "$mark" "$sname" "$age" "$host" "$swins"
  done < <(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}|#{session_created}')

  while IFS='|' read -r session win_idx win_name pane_idx pane_id pane_cmd pane_path pane_active screated; do
    local snippet mark age
    snippet="$(tmux capture-pane -pt "$pane_id" -S -20 2>/dev/null | tail -n 1 | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
    snippet="${snippet:0:90}"
    mark=" "
    [[ "$pane_active" == "1" ]] && mark="*"
    age="$(format_age "$screated")"
    printf 'pane\t%s\t%s pane %-24s age:%-7s host:%s cwd:%s cmd:%s :: %s\n' \
      "$pane_id" "$mark" "${session}:${win_idx}.${pane_idx} [${win_name}]" "$age" "$host" "$pane_path" "$pane_cmd" "$snippet"
  done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{window_name}|#{pane_index}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_active}|#{session_created}')
}

if [[ "${1:-}" == "--dump" ]]; then
  emit_rows
  exit 0
fi

tmp_file="$(mktemp -t tmux-fuzzy-panes.XXXXXX)"
cleanup() { rm -f "$tmp_file"; }
trap cleanup EXIT
emit_rows > "$tmp_file"

selected_line="$(cat "$tmp_file" | fzf \
  --delimiter='\t' \
  --with-nth=3 \
  --height=100% \
  --layout=reverse \
  --info=inline \
  --prompt='tmux jump > ' \
  --preview 'if [ "{1}" = "pane" ]; then tmux capture-pane -pt {2} -S -120 2>/dev/null | tail -n 120; else tmux list-windows -t {2}; fi' \
  --preview-window='right,60%,wrap' \
  --bind "ctrl-r:reload(${TMUXDESK}/bin/fuzzy-session-pane.sh --dump)" )"

[[ -n "$selected_line" ]] || exit 0
kind="$(printf '%s' "$selected_line" | cut -f1)"
target="$(printf '%s' "$selected_line" | cut -f2)"

if [[ "$kind" == "session" ]]; then
  tmux switch-client -t "$target"
  tmux display-message "fuzzy-jump → session ${target}"
  exit 0
fi

pane_id="$target"
target_session="$(tmux display-message -p -t "$pane_id" '#{session_name}')"
tmux switch-client -t "$target_session"
tmux select-pane -t "$pane_id"
tmux display-message "fuzzy-jump → ${target_session} ${pane_id}"
