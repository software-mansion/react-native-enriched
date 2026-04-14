#!/bin/bash
# run-tests.sh - Run Playwright tests.
#
# Usage:
#   ./run-tests.sh [--update-screenshots] [playwright-args...]
#
# Options:
#   --update-screenshots  Update screenshot baselines (maps to --update-snapshots).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

EXTRA=""

while [ $# -gt 0 ]; do
  case "$1" in
    --update-screenshots) EXTRA="$EXTRA --update-snapshots"; shift ;;
    *) EXTRA="$EXTRA $1"; shift ;;
  esac
done

cd "$REPO_ROOT"
# shellcheck disable=SC2086
playwright test --config .playwright/playwright.config.ts $EXTRA
