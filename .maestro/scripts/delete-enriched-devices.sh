#!/bin/bash
set -euo pipefail

DRY_RUN=true
[[ "${1:-}" == "--force" ]] && DRY_RUN=false || echo "[dry-run] Run with --force to actually delete."

do_delete() { if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi; }

echo "=== iOS Simulators ==="
xcrun simctl list devices | grep Enriched | grep -oE '[A-F0-9-]{36}' | while read -r id; do
  echo "Deleting $id..."
  do_delete xcrun simctl shutdown "$id" 2>/dev/null || true
  do_delete xcrun simctl delete "$id"
done || true

echo "=== Android AVDs ==="
avdmanager list avd -c | grep Enriched | while read -r name; do
  echo "Deleting $name..."
  do_delete pkill -f "emulator.*$name" 2>/dev/null || true
  do_delete avdmanager delete avd --name "$name"
done || true

echo ""
echo "Done."
