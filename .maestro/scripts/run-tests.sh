#!/bin/sh
# run-tests.sh - set up a device, build the example app, and run Maestro flows.
#
# Usage:
#   ./run-tests.sh --platform <ios|android> [--update-screenshots] [--skip-build] [flow ...]
#
# Options:
#   --platform            Required. Target platform: ios or android.
#   --update-screenshots  Passes UPDATE_SCREENSHOTS=true to Maestro (used by
#                         capture_or_assert_screenshot subflow to refresh baselines).
#   --skip-build          Skip building and installing the app. Useful when the app
#                         is already running on the device from a previous run.
#   flow ...              One or more Maestro flow files or directories to run.
#                         Defaults to .maestro/flows if omitted.
#
# Examples:
#   ./run-tests.sh --platform ios
#   ./run-tests.sh --platform android --update-screenshots .maestro/flows/core_controls_smoke.yaml
#   ./run-tests.sh --platform ios --skip-build .maestro/flows

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PLATFORM=""
UPDATE_SCREENSHOTS=""
SKIP_BUILD=""
FLOWS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)           PLATFORM="$2"; shift 2 ;;
    --update-screenshots) UPDATE_SCREENSHOTS="true"; shift ;;
    --skip-build)         SKIP_BUILD="true"; shift ;;
    *)                    FLOWS="${FLOWS:+$FLOWS }$1"; shift ;;
  esac
done

[ -z "$FLOWS" ] && FLOWS=".maestro/flows"

case "$PLATFORM" in
  ios)     SETUP="$SCRIPT_DIR/setup-ios-simulator.sh" ;;
  android) SETUP="$SCRIPT_DIR/setup-android-emulator.sh" ;;
  *)       echo "Error: --platform must be ios or android" >&2; exit 1 ;;
esac

DEVICE_ID=$("$SETUP" | tee /dev/tty | grep "^DEVICE_ID=" | cut -d= -f2)

if [ -z "$SKIP_BUILD" ]; then
  if [ "$PLATFORM" = ios ]; then
    yarn example ios --udid "$DEVICE_ID"
  else
    yarn example android --device "$DEVICE_ID"
  fi
fi

EXTRA=""
[ -n "$UPDATE_SCREENSHOTS" ] && EXTRA="--env UPDATE_SCREENSHOTS=true"

echo "=== Running maestro tests ==="
# shellcheck disable=SC2086
maestro test --device "$DEVICE_ID" $EXTRA $FLOWS
