#!/bin/sh
# run-tests-all.sh - run e2e tests on both iOS and Android sequentially.
#
# Usage:
#   ./run-tests-all.sh [options] [flow ...]
#
# All options (--update-screenshots, --rebuild, flow files, etc.) are
# forwarded to run-tests.sh for each platform.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo === iOS ===
"$SCRIPT_DIR/run-tests.sh" --platform ios "$@"

echo ""
echo "== android ==="
"$SCRIPT_DIR/run-tests.sh" --platform android "$@"
