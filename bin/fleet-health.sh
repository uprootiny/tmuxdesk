#!/usr/bin/env bash
# Fleet health dashboard — SSH to each peer, collect vitals, render table
# Used standalone or inside tmux popup (Prefix+F)
set -uo pipefail

FLEET_CONF="${HOME}/.tmux/tmuxdesk/fleet.conf"
LOCAL_NAME="$(tmux show -gqv @host_name 2>/dev/null || hostname -s)"
TIMEOUT=3

# Colors (ANSI)
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_CYAN='\033[36m'

printf "${C_BOLD}${C_CYAN}⊕ Fleet Health${C_RESET}  %s\n" "$(date '+%H:%M:%S')"
printf "${C_DIM}%-4s %-12s %-16s %-8s %-10s %-6s %s${C_RESET}\n" \
  "⊙" "NODE" "IP" "LOAD" "UPTIME" "SESS" "STATUS"
printf '%.0s─' {1..70}
echo

collect_remote() {
  local name="$1" alias="$2" sigil="$3" ip="$4"

  if [[ "$name" == "$LOCAL_NAME" ]]; then
    # Local node — no SSH needed
    local load up sess
    load="$(awk '{print $1}' /proc/loadavg 2>/dev/null || uptime | sed 's/.*load average: //' | cut -d, -f1 | tr -d ' ')"
    up="$(uptime -p 2>/dev/null | sed 's/up //' || uptime | sed 's/.*up //' | sed 's/,.*//')"
    up="${up:0:12}"
    sess="$(tmux list-sessions 2>/dev/null | wc -l || echo 0)"
    printf "${C_GREEN}%-4s${C_RESET} %-12s %-16s %-8s %-10s %-6s %s\n" \
      "$sigil" "$name" "$ip" "$load" "$up" "$sess" "● local"
    return 0
  fi

  # Remote node
  local result
  result="$(ssh -o ConnectTimeout="$TIMEOUT" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$alias" \
    'printf "%s|%s|%s" \
      "$(awk "{print \$1}" /proc/loadavg 2>/dev/null || echo "?")" \
      "$(uptime -p 2>/dev/null | sed "s/up //" || echo "?")" \
      "$(tmux list-sessions 2>/dev/null | wc -l || echo 0)"' 2>/dev/null)" || {
    printf "${C_RED}%-4s${C_RESET} %-12s %-16s %-8s %-10s %-6s %s\n" \
      "$sigil" "$name" "$ip" "−" "−" "−" "✕ unreachable"
    return 1
  }

  local load up sess
  IFS='|' read -r load up sess <<< "$result"
  up="${up:0:12}"
  printf "${C_GREEN}%-4s${C_RESET} %-12s %-16s %-8s %-10s %-6s %s\n" \
    "$sigil" "$name" "$ip" "$load" "$up" "$sess" "● ok"
}

# Collect from all nodes in parallel, preserve order
pids=()
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

idx=0
while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  (collect_remote "$name" "$alias" "$sigil" "$ip" > "${tmpdir}/${idx}") &
  pids+=($!)
  (( idx++ ))
done < "$FLEET_CONF"

# Wait for all
for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || true
done

# Print in order
for (( i=0; i<idx; i++ )); do
  cat "${tmpdir}/${i}" 2>/dev/null
done

echo
printf "${C_DIM}Press Enter to close${C_RESET}"
read -r
