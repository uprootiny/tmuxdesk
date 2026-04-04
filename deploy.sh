#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FLEET_CONF="${REPO_DIR}/fleet.conf"
DRY_RUN=0
TARGETS=()

# Parse args
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    DRY_RUN=1
  else
    TARGETS+=("$arg")
  fi
done

deploy_node() {
  local name="$1" alias="$2"

  echo "=== Deploying to ${name} (${alias}) ==="

  if (( DRY_RUN )); then
    echo "  [dry-run] rsync ${REPO_DIR}/ → ${alias}:~/.tmux/tmuxdesk/"
    echo "  [dry-run] write ~/.tmux.conf sourcing base + host-${name}.conf"
    return 0
  fi

  # Ensure remote directory structure
  ssh -T -o RemoteCommand=none -o ConnectTimeout=5 -o BatchMode=yes "$alias" \
    'mkdir -p ~/.tmux/tmuxdesk/{bin,conf,presets,state}' || {
    echo "  FAIL: cannot reach ${alias}"
    return 1
  }

  # Rsync the repo
  rsync -avz --delete \
    --exclude='.git' \
    --exclude='state/*' \
    --exclude='.claude/' \
    --exclude='.gitignore' \
    -e "ssh -o RemoteCommand=none" \
    "${REPO_DIR}/" "${alias}:~/.tmux/tmuxdesk/"

  # Write per-host ~/.tmux.conf
  ssh -T -o RemoteCommand=none "$alias" "cat > ~/.tmux.conf" <<EOF
# Managed by tmuxdesk — do not edit directly
source-file ~/.tmux/tmuxdesk/conf/tmux.base.conf
source-file ~/.tmux/tmuxdesk/conf/host-${name}.conf
EOF

  # Substitute @tmuxdesk@ placeholder → ~/.tmux/tmuxdesk for rsync deploys
  ssh -T -o RemoteCommand=none "$alias" \
    "find ~/.tmux/tmuxdesk/bin ~/.tmux/tmuxdesk/conf ~/.tmux/tmuxdesk/presets -type f 2>/dev/null | xargs sed -i.bak 's|@tmuxdesk@|~/.tmux/tmuxdesk|g' 2>/dev/null; find ~/.tmux/tmuxdesk -name '*.bak' -delete 2>/dev/null || true"

  # Make scripts executable
  ssh -T -o RemoteCommand=none "$alias" 'chmod +x ~/.tmux/tmuxdesk/bin/*.sh ~/.tmux/tmuxdesk/presets/*.sh 2>/dev/null || true'

  # Reload tmux if running
  ssh -T -o RemoteCommand=none "$alias" 'tmux source-file ~/.tmux.conf 2>/dev/null && echo "  tmux reloaded" || echo "  tmux not running"'

  echo "  OK: ${name} deployed"
}

# Build target list
nodes=()
while read -r name alias sigil ip; do
  [[ "$name" == "#"* || -z "$name" ]] && continue
  if (( ${#TARGETS[@]} == 0 )); then
    nodes+=("$name|$alias")
  else
    for t in "${TARGETS[@]}"; do
      [[ "$t" == "$name" || "$t" == "$alias" ]] && nodes+=("$name|$alias")
    done
  fi
done < "$FLEET_CONF"

if (( ${#nodes[@]} == 0 )); then
  echo "No matching nodes found."
  exit 1
fi

# Deploy
failed=0
for entry in "${nodes[@]}"; do
  IFS='|' read -r name alias <<< "$entry"
  deploy_node "$name" "$alias" || (( failed++ ))
done

echo ""
echo "Done. ${#nodes[@]} nodes targeted, ${failed} failed."
