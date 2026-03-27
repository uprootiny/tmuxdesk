#!/usr/bin/env bash
# Render local server sigil + state indicator for status-left
# Output: 🜂●3 (sigil, attached dot, session count)
set -euo pipefail

sigil="$(tmux show -gqv @host_sigil 2>/dev/null)"
[[ -z "$sigil" ]] && sigil="?"

# Count sessions and check attachment
total="$(tmux list-sessions 2>/dev/null | wc -l)"
attached="$(tmux list-sessions -F '#{session_attached}' 2>/dev/null | grep -c '^1$' || true)"

if (( attached > 0 )); then
  printf '%s●%s' "$sigil" "$total"
else
  printf '%s○%s' "$sigil" "$total"
fi
