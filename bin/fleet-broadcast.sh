#!/usr/bin/env bash
# fleet-broadcast.sh — Send a command to all fleet nodes in parallel
#
# Usage:
#   fleet-broadcast.sh "uptime"          # run 'uptime' on every node
#   fleet-broadcast.sh                   # interactive: prompts via tmux command-prompt
#
# Reads fleet.conf for node list, SSHes to each in parallel with a 3s timeout,
# collects output, and displays results grouped by node (with sigils).
#
# If running inside tmux, results are shown in a tmux popup (or pager fallback).
# If running outside tmux, results go to stdout.
set -euo pipefail

TMUXDESK_DIR="${TMUXDESK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FLEET_CONF="${TMUXDESK_DIR}/fleet.conf"
SSH_TIMEOUT=3  # seconds per node

# ---------------------------------------------------------------------------
# Get command to broadcast
# ---------------------------------------------------------------------------
if [[ $# -ge 1 ]]; then
  CMD="$1"
else
  # Interactive mode: if inside tmux, use command-prompt
  if [[ -n "${TMUX:-}" ]]; then
    # tmux command-prompt runs asynchronously, so we re-invoke ourselves with the arg
    tmux command-prompt -p "broadcast:" \
      "run-shell '${BASH_SOURCE[0]} \"%%\"'"
    exit 0
  else
    printf "Command to broadcast: "
    read -r CMD
    if [[ -z "$CMD" ]]; then
      echo "No command given." >&2
      exit 1
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Parse fleet.conf into arrays
# ---------------------------------------------------------------------------
declare -a NAMES=() ALIASES=() SIGILS=()

while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  NAMES+=("$name")
  ALIASES+=("$alias")
  SIGILS+=("$sigil")
done < "$FLEET_CONF"

if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "No nodes found in ${FLEET_CONF}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Run command on all nodes in parallel, capture output to temp files
# ---------------------------------------------------------------------------
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

pids=()
for i in "${!NAMES[@]}"; do
  alias="${ALIASES[$i]}"
  outfile="${TMPDIR_WORK}/${i}.out"
  (
    # ConnectTimeout for TCP; total timeout via the wrapper timeout command
    # Use GNU timeout on Linux, gtimeout on macOS if available, else background+kill
    if command -v timeout &>/dev/null; then
      timeout "${SSH_TIMEOUT}s" \
        ssh -o ConnectTimeout="${SSH_TIMEOUT}" \
            -o StrictHostKeyChecking=no \
            -o BatchMode=yes \
            "$alias" "$CMD" \
        > "$outfile" 2>&1
    elif command -v gtimeout &>/dev/null; then
      gtimeout "${SSH_TIMEOUT}s" \
        ssh -o ConnectTimeout="${SSH_TIMEOUT}" \
            -o StrictHostKeyChecking=no \
            -o BatchMode=yes \
            "$alias" "$CMD" \
        > "$outfile" 2>&1
    else
      # Fallback: background ssh with a kill timer
      ssh -o ConnectTimeout="${SSH_TIMEOUT}" \
          -o StrictHostKeyChecking=no \
          -o BatchMode=yes \
          "$alias" "$CMD" \
        > "$outfile" 2>&1 &
      local_pid=$!
      ( sleep "$SSH_TIMEOUT"; kill "$local_pid" 2>/dev/null ) &
      killer=$!
      wait "$local_pid" 2>/dev/null
      kill "$killer" 2>/dev/null
      wait "$killer" 2>/dev/null
    fi
  ) &
  pids+=($!)
done

# Wait for all background jobs
for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# Assemble formatted output
# ---------------------------------------------------------------------------
result=""
for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  sigil="${SIGILS[$i]}"
  outfile="${TMPDIR_WORK}/${i}.out"

  result+="${sigil} ${name}"$'\n'

  if [[ -f "$outfile" && -s "$outfile" ]]; then
    # Indent each line of output by 2 spaces
    while IFS= read -r line; do
      result+="  ${line}"$'\n'
    done < "$outfile"
  elif [[ -f "$outfile" ]]; then
    result+="  (no output)"$'\n'
  else
    result+="  (timeout / unreachable)"$'\n'
  fi
done

# ---------------------------------------------------------------------------
# Display results
# ---------------------------------------------------------------------------
if [[ -n "${TMUX:-}" ]]; then
  # Write to a temp file for the popup/pager
  result_file="${TMPDIR_WORK}/result.txt"
  printf '%s' "$result" > "$result_file"

  # Try tmux popup first (tmux 3.2+), fall back to new-window with less
  if tmux display-popup -h 80% -w 80% -E "cat '${result_file}'; echo; echo '[press any key]'; read -rsn1" 2>/dev/null; then
    : # popup succeeded
  else
    # Fallback: open in a temporary pane with less
    tmux new-window -n "broadcast" "cat '${result_file}' | less -R; rm -rf '${TMPDIR_WORK}'"
    # Don't let trap remove the dir if new-window took ownership
    trap - EXIT
  fi
else
  # Outside tmux: just print to stdout
  printf '%s' "$result"
fi
