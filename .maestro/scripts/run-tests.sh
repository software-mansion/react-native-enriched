#!/bin/bash
# run-tests.sh - set up a device, build the example app, and run Maestro flows.
#
# Usage:
#   ./run-tests.sh --platform <ios|android> [--update-screenshots] [--rebuild] [flow ...]
#
# Options:
#   --platform            Required. Target platform: ios or android.
#   --update-screenshots  Refresh baselines.
#   --rebuild             Force a rebuild and install, even if the app is
#                         already installed on the device.
#   flow ...              One or more Maestro flow files or directories to run.
#                         Defaults to .maestro/flows if omitted.
#
# Examples:
#   ./run-tests.sh --platform ios
#   ./run-tests.sh --platform android --update-screenshots .maestro/flows/core_controls_smoke.yaml
#   ./run-tests.sh --platform ios --rebuild

set -euo pipefail

MIN_MAESTRO_VERSION="2.3.0"

if ! command -v maestro >/dev/null 2>&1; then
  echo "Error: maestro CLI not found." >&2
  exit 1
fi

MAESTRO_VERSION=$(maestro --version)
# Compare versions by sorting them; if the minimum sorts after the actual, it's too old.
if [ "$(printf '%s\n' "$MIN_MAESTRO_VERSION" "$MAESTRO_VERSION" | sort -V | head -n1)" != "$MIN_MAESTRO_VERSION" ]; then
  echo "Error: maestro $MAESTRO_VERSION is too old, minimum required is $MIN_MAESTRO_VERSION" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_ID="swmansion.enriched.example"

PLATFORM=""
UPDATE_SCREENSHOTS=""
REBUILD=""
FLOWS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)           PLATFORM="$2"; shift 2 ;;
    --update-screenshots) UPDATE_SCREENSHOTS="true"; shift ;;
    --rebuild)            REBUILD="true"; shift ;;
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

app_installed() {
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl listapps "$DEVICE_ID" 2>/dev/null | grep -q "$BUNDLE_ID"
  else
    adb -s "$DEVICE_ID" shell pm list packages "$BUNDLE_ID" 2>/dev/null | grep -q "$BUNDLE_ID"
  fi
}

if [ -n "$REBUILD" ] || ! app_installed; then
  [ -n "$REBUILD" ] && echo "=== rebuild requested, building and installing ==="
  [ -z "$REBUILD" ] && echo "=== App ($BUNDLE_ID) not found, building and installing ==="
  if [ "$PLATFORM" = ios ]; then
    yarn example ios --udid "$DEVICE_ID"
  else
    yarn example android --device "$DEVICE_ID"
  fi
else
  echo "=== App ($BUNDLE_ID) already installed, skipping build ==="
fi

EXTRA=""
[ -n "$UPDATE_SCREENSHOTS" ] && EXTRA="--env UPDATE_SCREENSHOTS=true"

# Exclude tests tagged for the other platform.
case "$PLATFORM" in
  ios)     EXTRA="$EXTRA --exclude-tags android-only" ;;
  android) EXTRA="$EXTRA --exclude-tags ios-only" ;;
esac

# Maestro resolves addMedia paths by walking the workspace inputs. Since assets
# live outside the flows directory, always include it so media files are found.
ASSETS_DIR=".maestro/assets"
[ -d "$ASSETS_DIR" ] && FLOWS="$ASSETS_DIR $FLOWS"

echo "=== Running maestro tests ==="
# shellcheck disable=SC2086
maestro test --device "$DEVICE_ID" $EXTRA $FLOWS
