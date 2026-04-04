#!/usr/bin/env bash
# Install tmuxdesk iTerm2 dynamic profiles
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/tmuxdesk-profiles.json"
DEST_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
DEST="$DEST_DIR/tmuxdesk.json"

if [[ ! -f "$SRC" ]]; then
  echo "error: $SRC not found" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "installed → $DEST"
echo "restart iTerm2 or open Preferences to see the tmuxdesk profiles"
