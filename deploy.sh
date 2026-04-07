#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FLEET_CONF="${REPO_DIR}/fleet.conf"
DRY_RUN=0
VERIFY=0
TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verify)  VERIFY=1 ;;
    *)         TARGETS+=("$arg") ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
validate_node() {
  local name="$1"
  local host_conf="${REPO_DIR}/conf/host-${name}.conf"
  if [[ ! -f "$host_conf" ]]; then
    echo "  ERROR: conf/host-${name}.conf does not exist" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Deploy
# ---------------------------------------------------------------------------
deploy_node() {
  local name="$1" alias="$2"

  echo "=== ${name} (${alias}) ==="

  validate_node "$name" || return 1

  if (( DRY_RUN )); then
    echo "  [dry-run] rsync → ${alias}:~/.tmux/tmuxdesk/"
    echo "  [dry-run] write ~/.tmux.conf"
    return 0
  fi

  # Reach check
  ssh -T -o RemoteCommand=none -o ConnectTimeout=5 -o BatchMode=yes "$alias" \
    'mkdir -p ~/.tmux/tmuxdesk/{bin,conf,presets,state}' || {
    echo "  FAIL: cannot reach ${alias}"
    return 1
  }

  # Sync
  rsync -az --delete \
    --exclude='.git' \
    --exclude='state/*' \
    --exclude='.claude/' \
    --exclude='.gitignore' \
    --exclude='fleet-status/target/' \
    --exclude='web/node_modules/' \
    --exclude='web/.shadow-cljs/' \
    --exclude='flake.lock' \
    --exclude='result' \
    --exclude='*.log' \
    -e "ssh -o RemoteCommand=none" \
    "${REPO_DIR}/" "${alias}:~/.tmux/tmuxdesk/" 2>&1 | \
    grep -c '^' | xargs -I{} echo "  {} files synced"

  # Write ~/.tmux.conf
  ssh -T -o RemoteCommand=none "$alias" "cat > ~/.tmux.conf" <<EOF
# Managed by tmuxdesk — do not edit directly
source-file ~/.tmux/tmuxdesk/conf/tmux.base.conf
source-file ~/.tmux/tmuxdesk/conf/host-${name}.conf
EOF

  # Permissions
  ssh -T -o RemoteCommand=none "$alias" \
    'chmod +x ~/.tmux/tmuxdesk/bin/*.sh ~/.tmux/tmuxdesk/presets/*.sh 2>/dev/null || true'

  # Reload
  if ssh -T -o RemoteCommand=none "$alias" 'tmux source-file ~/.tmux.conf 2>/dev/null'; then
    echo "  OK (reloaded)"
  else
    echo "  OK (tmux not running)"
  fi
}

# ---------------------------------------------------------------------------
# Verify — check that deployed config is healthy
# ---------------------------------------------------------------------------
verify_node() {
  local name="$1" alias="$2" sigil="$3"
  local ok=1

  # Can we reach it?
  if ! ssh -T -o RemoteCommand=none -o ConnectTimeout=3 -o BatchMode=yes "$alias" 'true' 2>/dev/null; then
    printf '  %s %-12s  unreachable\n' "$sigil" "$name"
    return 1
  fi

  # Is tmux running?
  local tmux_status
  tmux_status="$(ssh -T -o RemoteCommand=none "$alias" \
    'tmux list-sessions -F "#{session_name}" 2>/dev/null | wc -l | tr -d " "' 2>/dev/null || echo "0")"

  # Does the config source correctly?
  local conf_ok
  conf_ok="$(ssh -T -o RemoteCommand=none "$alias" \
    'test -f ~/.tmux.conf && grep -c "tmuxdesk" ~/.tmux.conf' 2>/dev/null || echo "0")"

  # Sigil check
  local remote_sigil
  remote_sigil="$(ssh -T -o RemoteCommand=none "$alias" \
    'tmux show -gqv @host_sigil 2>/dev/null' 2>/dev/null || echo "?")"

  local status_str=""
  [[ "$conf_ok" -gt 0 ]] && status_str+="conf:ok " || { status_str+="conf:MISSING "; ok=0; }
  [[ "$tmux_status" -gt 0 ]] && status_str+="tmux:${tmux_status}s " || status_str+="tmux:stopped "
  [[ "$remote_sigil" == "$sigil" ]] && status_str+="sigil:${remote_sigil}" || { status_str+="sigil:MISMATCH(${remote_sigil})"; ok=0; }

  printf '  %s %-12s  %s\n' "$sigil" "$name" "$status_str"
  return $(( 1 - ok ))
}

# ---------------------------------------------------------------------------
# Build target list
# ---------------------------------------------------------------------------
nodes=()
while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  if (( ${#TARGETS[@]} == 0 )); then
    nodes+=("$name|$alias|$sigil")
  else
    for t in "${TARGETS[@]}"; do
      [[ "$t" == "$name" || "$t" == "$alias" ]] && nodes+=("$name|$alias|$sigil")
    done
  fi
done < "$FLEET_CONF"

if (( ${#nodes[@]} == 0 )); then
  echo "No matching nodes in fleet.conf."
  exit 1
fi

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
if (( VERIFY )); then
  echo "=== Fleet verification ==="
  failed=0
  for entry in "${nodes[@]}"; do
    IFS='|' read -r name alias sigil <<< "$entry"
    verify_node "$name" "$alias" "$sigil" || (( failed++ )) || true
  done
  echo ""
  echo "${#nodes[@]} nodes checked, ${failed} issues."
  exit "$failed"
fi

failed=0
for entry in "${nodes[@]}"; do
  IFS='|' read -r name alias sigil <<< "$entry"
  deploy_node "$name" "$alias" || (( failed++ )) || true
done

echo ""
if (( failed > 0 )); then
  echo "Done. ${#nodes[@]} targeted, ${failed} failed."
  exit 1
else
  echo "Done. ${#nodes[@]} nodes deployed."
fi
