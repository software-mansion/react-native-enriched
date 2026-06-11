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
#                         Defaults to all component suites if omitted.
#
# Examples:
#   ./run-tests.sh --platform ios
#   ./run-tests.sh --platform android --update-screenshots .maestro/enrichedInput/flows/core_controls_smoke.yaml
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
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAESTRO_ROOT="$REPO_ROOT/.maestro"
SCREENSHOT_ROOT="$MAESTRO_ROOT"
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

[ -z "$FLOWS" ] && FLOWS=".maestro/enrichedInput/flows .maestro/enrichedText/flows"

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

# Adjusts the system's text-size setting.
set_font_scale() {
  case "$1" in
    default) ios_size="large";               android_scale="1.0" ;;
    large)   ios_size="accessibility-large"; android_scale="1.5" ;;
    *) echo "set_font_scale: unknown size '$1'" >&2; return 1 ;;
  esac
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl ui "$DEVICE_ID" content_size "$ios_size"
  else
    adb -s "$DEVICE_ID" shell settings put system font_scale "$android_scale"
  fi
}

# Guarantees the font scale is restored on any exit.
# Without this, the accessibility tests below would leave the device
# in a scaled-up state.
trap 'set_font_scale default' EXIT

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

EXTRA="--env SCREENSHOT_ROOT=$SCREENSHOT_ROOT"
[ -n "$UPDATE_SCREENSHOTS" ] && EXTRA="$EXTRA --env UPDATE_SCREENSHOTS=true"

# Exclude tests tagged for the other platform.
case "$PLATFORM" in
  ios)     EXTRA="$EXTRA --exclude-tags android-only" ;;
  android) EXTRA="$EXTRA --exclude-tags ios-only" ;;
esac

# Maestro resolves addMedia paths by walking the workspace inputs. Since assets
# live outside the flows directory, always include it so media files are found.
ASSETS_DIR="$MAESTRO_ROOT/assets"
[ -d "$ASSETS_DIR" ] && FLOWS="$ASSETS_DIR $FLOWS"

# A previous run could have died before its EXIT trap fired (e.g. SIGKILL),
# leaving the device scaled. Force a known state before the normal tests.
set_font_scale default

# maestro exits non-zero when the tag filter matches zero flows. That's not a
# real failure for us (e.g. running a single flow that has no accessibility
# variant), and letting it propagate aborts latter test suites.
run_maestro() {
  local tmp rc
  tmp=$(mktemp)
  # `script` allocates a pseudo-TTY so maestro keeps
  # ANSI colors when piped through `tee`.
  if [[ "$OSTYPE" == darwin* ]]; then
    script -q /dev/null maestro test "$@" 2>&1 | tee "$tmp"
  else
    local cmd
    cmd=$(printf '%q ' maestro test "$@")
    script -qc "$cmd" /dev/null 2>&1 | tee "$tmp"
  fi
  rc=${PIPESTATUS[0]}
  if [ "$rc" -ne 0 ] && grep -q "did not match any Flows" "$tmp"; then
    echo "warn: no flows matched the tag filter — treating as success" >&2
    rc=0
  fi
  rm -f "$tmp"
  return "$rc"
}

set +e

echo "=== Running maestro tests ==="
# shellcheck disable=SC2086
run_maestro --device "$DEVICE_ID" --exclude-tags accessibility $EXTRA $FLOWS
EXIT_REGULAR=$?

# These are the tests that require changing the system's settings
# - something maestro cannot run internally
echo "=== Running maestro accessibility tests ==="
set_font_scale large

# shellcheck disable=SC2086
run_maestro --device "$DEVICE_ID" --include-tags accessibility $EXTRA $FLOWS
EXIT_A11Y=$?

set -e

exit $(( EXIT_REGULAR != 0 || EXIT_A11Y != 0 ))
