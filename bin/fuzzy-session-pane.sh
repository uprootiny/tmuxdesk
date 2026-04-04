#!/usr/bin/env bash
# fuzzy-session-pane.sh — fuzzy session/pane jumper with cross-fleet navigation
# Lists local tmux sessions+panes and remote fleet sessions via mesh state files.
# Requires: tmux, fzf (falls back to choose-tree without fzf)
set -euo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-@tmuxdesk@}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
STATE_DIR="${HOME}/.tmux/tmuxdesk/state"
STALE_THRESHOLD=300  # 5 minutes in seconds

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# The local hostname as tmux knows it (used to skip ourselves in fleet.conf)
LOCAL_HOST="$(tmux show -gqv @host_name 2>/dev/null || hostname -s)"
LOCAL_SIGIL="$(tmux show -gqv @host_sigil 2>/dev/null || echo '?')"

# Format seconds-since-epoch into a compact age string like "2d5h" or "37m"
format_age() {
  local created="${1:-0}" now delta d h m
  now="$(date +%s)"
  delta=$(( now - created ))
  (( delta < 0 )) && delta=0
  d=$(( delta / 86400 ))
  h=$(( (delta % 86400) / 3600 ))
  m=$(( (delta % 3600) / 60 ))
  if (( d > 0 )); then printf '%dd%dh' "$d" "$h"; return; fi
  if (( h > 0 )); then printf '%dh%dm' "$h" "$m"; return; fi
  printf '%dm' "$m"
}

# ---------------------------------------------------------------------------
# Fleet config reader
# Returns lines: name ssh_alias sigil ip
# Skips comments, blank lines, and the local host.
# ---------------------------------------------------------------------------
read_fleet() {
  [[ -f "$FLEET_CONF" ]] || return 0
  while read -r name alias sigil ip _rest; do
    [[ -z "$name" || "$name" == "#"* ]] && continue
    [[ "$name" == "$LOCAL_HOST" ]] && continue
    printf '%s %s %s %s\n' "$name" "$alias" "$sigil" "$ip"
  done < "$FLEET_CONF"
}

# ---------------------------------------------------------------------------
# Emit rows — called once to build the fzf input.
# Row format (tab-separated):
#   kind \t target \t display_text
#
# Kinds:
#   session  — local tmux session, target = session name
#   pane     — local tmux pane, target = pane id (%N)
#   remote   — remote session, target = alias:::session_name
# ---------------------------------------------------------------------------
emit_rows() {

  # ── Local sessions ──────────────────────────────────────────────────────
  printf 'header\t_\t── %s local ──\n' "$LOCAL_SIGIL"

  # Sessions
  while IFS='|' read -r sname swins satt screated; do
    local mark=" "
    [[ "$satt" == "1" ]] && mark="*"
    local age
    age="$(format_age "$screated")"
    printf 'session\t%s\t%s session %-16s age:%-7s host:%s windows:%s\n' \
      "$sname" "$mark" "$sname" "$age" "$LOCAL_HOST" "$swins"
  done < <(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}|#{session_created}')

  # Panes
  while IFS='|' read -r session win_idx win_name pane_idx pane_id pane_cmd pane_path pane_active screated; do
    local snippet mark age
    snippet="$(tmux capture-pane -pt "$pane_id" -S -20 2>/dev/null | tail -n 1 | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')" || snippet=""
    snippet="${snippet:0:90}"
    mark=" "
    [[ "$pane_active" == "1" ]] && mark="*"
    age="$(format_age "$screated")"
    printf 'pane\t%s\t%s pane %-24s age:%-7s host:%s cwd:%s cmd:%s :: %s\n' \
      "$pane_id" "$mark" "${session}:${win_idx}.${pane_idx} [${win_name}]" "$age" "$LOCAL_HOST" "$pane_path" "$pane_cmd" "$snippet"
  done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{window_name}|#{pane_index}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_active}|#{session_created}')

  # ── Remote fleet sessions ───────────────────────────────────────────────
  while read -r rname ralias rsigil _rip; do
    local state_file="${STATE_DIR}/${rname}.sessions"

    # Check if state file exists and is fresh
    if [[ ! -f "$state_file" ]]; then
      printf 'header\t_\t── %s %s (offline — no state) ──\n' "$rsigil" "$rname"
      continue
    fi

    local file_age now file_mtime
    now="$(date +%s)"
    # macOS stat vs GNU stat
    if stat -f '%m' /dev/null &>/dev/null; then
      file_mtime="$(stat -f '%m' "$state_file")"
    else
      file_mtime="$(stat -c '%Y' "$state_file")"
    fi
    file_age=$(( now - file_mtime ))

    if (( file_age > STALE_THRESHOLD )); then
      printf 'header\t_\t── %s %s (stale — %ds ago) ──\n' "$rsigil" "$rname" "$file_age"
      continue
    fi

    printf 'header\t_\t── %s %s ──\n' "$rsigil" "$rname"

    # Parse state file: session_name|is_attached|window_count
    while IFS='|' read -r rsess ratt rwins; do
      [[ -z "$rsess" || "$rsess" == "#"* ]] && continue
      local rmark=" "
      [[ "$ratt" == "1" ]] && rmark="*"
      # target encodes alias and session separated by :::
      printf 'remote\t%s:::%s\t%s %s remote %-16s host:%-12s windows:%-3s %s\n' \
        "$ralias" "$rsess" "$rmark" "$rsigil" "$rsess" "$rname" "$rwins" \
        "$(if [[ "$ratt" == "1" ]]; then echo "[attached]"; else echo ""; fi)"
    done < "$state_file"

  done < <(read_fleet)
}

# ---------------------------------------------------------------------------
# Preview script — invoked by fzf for the focused row.
# Receives kind and target as positional args.
# ---------------------------------------------------------------------------
preview_cmd() {
  local kind="$1" target="$2"
  case "$kind" in
    session)
      # Show last 120 lines of the first pane, plus window list
      echo "=== Windows ==="
      tmux list-windows -t "$target" 2>/dev/null || echo "(no windows)"
      echo ""
      echo "=== Pane content ==="
      tmux capture-pane -pt "${target}:1" -S -120 2>/dev/null | tail -n 120 || echo "(no capture)"
      ;;
    pane)
      tmux capture-pane -pt "$target" -S -120 2>/dev/null | tail -n 120 || echo "(no capture)"
      ;;
    remote)
      # target is alias:::session_name
      local alias="${target%%:::*}"
      local sess="${target#*:::}"
      echo "=== Remote: ${alias} / ${sess} ==="
      ssh -o ConnectTimeout=2 -o BatchMode=yes "$alias" \
        "tmux capture-pane -pt '${sess}:1' -S -60 2>/dev/null || tmux list-windows -t '${sess}' 2>/dev/null || echo '(session not reachable)'" \
        2>/dev/null || echo "(SSH failed — host may be unreachable)"
      ;;
    header)
      echo "(section header)"
      ;;
    *)
      echo "(unknown row type: $kind)"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Entry points
# ---------------------------------------------------------------------------

# --dump: emit rows to stdout (used by ctrl-r reload)
if [[ "${1:-}" == "--dump" ]]; then
  emit_rows
  exit 0
fi

# --preview KIND TARGET: render preview for a single row (called by fzf)
if [[ "${1:-}" == "--preview" ]]; then
  preview_cmd "${2:-header}" "${3:-_}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Fallback if fzf is not installed — local only, no fleet
# ---------------------------------------------------------------------------
if ! command -v fzf >/dev/null 2>&1; then
  tmux choose-tree -Zw
  exit 0
fi

# ---------------------------------------------------------------------------
# Main: build row list, launch fzf, act on selection
# ---------------------------------------------------------------------------
SELF_PATH="${TMUXDESK}/bin/fuzzy-session-pane.sh"

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
  --ansi \
  --prompt="${LOCAL_SIGIL} jump > " \
  --header="local + fleet  |  ctrl-r: refresh" \
  --preview "${SELF_PATH} --preview {1} {2}" \
  --preview-window='right,60%,wrap' \
  --bind "ctrl-r:reload(${SELF_PATH} --dump)" \
)" || true

# Nothing selected (user pressed Esc)
[[ -n "$selected_line" ]] || exit 0

kind="$(printf '%s' "$selected_line" | cut -f1)"
target="$(printf '%s' "$selected_line" | cut -f2)"

case "$kind" in
  session)
    # Local session — switch to it
    tmux switch-client -t "$target"
    tmux display-message "fuzzy-jump -> session ${target}"
    ;;

  pane)
    # Local pane — switch to its session, then select the pane
    pane_id="$target"
    target_session="$(tmux display-message -p -t "$pane_id" '#{session_name}')"
    tmux switch-client -t "$target_session"
    tmux select-pane -t "$pane_id"
    tmux display-message "fuzzy-jump -> ${target_session} ${pane_id}"
    ;;

  remote)
    # Remote session — open new window with SSH attach
    alias="${target%%:::*}"
    sess="${target#*:::}"
    tmux new-window -n "r:${sess}" "ssh -t ${alias} 'tmux new-session -A -s ${sess}'"
    tmux display-message "fuzzy-jump -> remote ${alias}:${sess}"
    ;;

  header)
    # Section header selected — ignore silently
    ;;

  *)
    tmux display-message "fuzzy-jump: unknown kind '${kind}'"
    ;;
esac
