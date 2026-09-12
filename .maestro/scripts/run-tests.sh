#!/bin/bash
# run-tests.sh - set up devices, build the example app, and run Maestro flows.
#
# Usage:
#   ./run-tests.sh --platform <ios|android> [--update-screenshots] [--rebuild] [--shards N] [flow ...]
#
# Options:
#   --platform            Required. Target platform: ios or android.
#   --update-screenshots  Refresh baselines.
#   --rebuild             Force a rebuild and install, even if the app is
#                         already installed on the device.
#   --shards N            Number of devices to boot and split flows across
#                         (default 1). Automatically clamped to the number of
#                         flows being run.
#   flow ...              One or more Maestro flow files or directories to run.
#                         Defaults to all component suites if omitted.
#
# Examples:
#   ./run-tests.sh --platform ios
#   ./run-tests.sh --platform android --update-screenshots .maestro/enrichedInput/flows/core_controls_smoke.yaml
#   ./run-tests.sh --platform ios --rebuild --shards 2

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
EXAMPLE_DIR="$REPO_ROOT/apps/example"

PLATFORM=""
UPDATE_SCREENSHOTS=""
REBUILD=""
SHARDS=1
FLOWS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)           PLATFORM="$2"; shift 2 ;;
    --update-screenshots) UPDATE_SCREENSHOTS="true"; shift ;;
    --rebuild)            REBUILD="true"; shift ;;
    --shards)             SHARDS="$2"; shift 2 ;;
    *)                    FLOWS="${FLOWS:+$FLOWS }$1"; shift ;;
  esac
done

if ! [[ "$SHARDS" =~ ^[0-9]+$ ]]; then
  echo "Error: --shards requires a numeric integer. Received: '$SHARDS'" >&2
  exit 1
fi

[ -z "$FLOWS" ] && FLOWS=".maestro/enrichedInput/flows .maestro/enrichedText/flows"

case "$PLATFORM" in
  ios)     SETUP="$SCRIPT_DIR/setup-ios-simulator.sh" ;;
  android) SETUP="$SCRIPT_DIR/setup-android-emulator.sh" ;;
  *)       echo "Error: --platform must be ios or android" >&2; exit 1 ;;
esac

# No point booting more devices than there are flows to run
# (e.g. when running a single flow file).
FLOW_COUNT=0
for f in $FLOWS; do
  if [ -d "$f" ]; then
    n=$(find "$f" -name '*.yaml' | wc -l | tr -d ' ')
  elif [ -f "$f" ]; then
    n=1
  else
    n=0
  fi
  FLOW_COUNT=$((FLOW_COUNT + n))
done
if [ "$FLOW_COUNT" -gt 0 ] && [ "$SHARDS" -gt "$FLOW_COUNT" ]; then
  SHARDS=$FLOW_COUNT
fi
[ "$SHARDS" -lt 1 ] && SHARDS=1

# Stream setup progress to the terminal; fall back to stderr when
# no TTY is attached (e.g. CI).
TTY_OUT=/dev/tty
( : > /dev/tty ) 2>/dev/null || TTY_OUT=/dev/stderr

DEVICE_IDS_CSV=$("$SETUP" "$SHARDS" | tee "$TTY_OUT" | grep "^DEVICE_IDS=" | cut -d= -f2)
if [ -z "$DEVICE_IDS_CSV" ]; then
  echo "Error: setup script did not return any DEVICE_IDS" >&2
  exit 1
fi
IFS=',' read -r -a DEVICES <<< "$DEVICE_IDS_CSV"
DEVICE_ID="${DEVICES[0]}"

app_installed() {
  local dev="$1"
  if [ "$PLATFORM" = ios ]; then
    xcrun simctl listapps "$dev" 2>/dev/null | grep -q "$BUNDLE_ID"
  else
    adb -s "$dev" shell pm list packages "$BUNDLE_ID" 2>/dev/null | grep -q "$BUNDLE_ID"
  fi
}

# Adjusts the system's text-size setting on every shard device.
set_font_scale() {
  local dev
  case "$1" in
    default) ios_size="large";               android_scale="1.0" ;;
    large)   ios_size="accessibility-large"; android_scale="1.5" ;;
    *) echo "set_font_scale: unknown size '$1'" >&2; return 1 ;;
  esac
  for dev in "${DEVICES[@]}"; do
    if [ "$PLATFORM" = ios ]; then
      xcrun simctl ui "$dev" content_size "$ios_size"
    else
      adb -s "$dev" shell settings put system font_scale "$android_scale"
    fi
  done
}

# Guarantees the font scale is restored on any exit.
# Without this, the accessibility tests below would leave the device
# in a scaled-up state.
trap 'set_font_scale default' EXIT

# Builds and installs on the given device via the react-native CLI.
build_and_install() {
  local dev="$1"
  if [ "$PLATFORM" = ios ]; then
    yarn example ios --udid "$dev"
  else
    yarn example android --device "$dev"
  fi
}

# Installs the already-built app artifact on the given device. Tries the
# build output first, then the copy installed on the primary device, and
# only falls back to a full build if neither exists.
install_prebuilt() {
  local dev="$1" app_path apk_path
  if [ "$PLATFORM" = ios ]; then
    app_path=$(ls -td "$EXAMPLE_DIR/ios/build/Build/Products/Debug-iphonesimulator"/*.app 2>/dev/null | head -1 || true)
    if [ -z "$app_path" ]; then
      app_path=$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" app 2>/dev/null || true)
    fi
    if [ -n "$app_path" ]; then
      echo "=== Installing prebuilt app on $dev ==="
      xcrun simctl install "$dev" "$app_path"
    else
      echo "warn: no prebuilt .app found, building for $dev" >&2
      build_and_install "$dev"
    fi
  else
    apk_path=$(ls -t "$EXAMPLE_DIR/android/app/build/outputs/apk/debug"/*.apk 2>/dev/null | head -1 || true)
    if [ -z "$apk_path" ]; then
      local device_apk
      device_apk=$(adb -s "$DEVICE_ID" shell pm path "$BUNDLE_ID" 2>/dev/null | head -1 | cut -d: -f2 | tr -d '\r' || true)
      if [ -n "$device_apk" ]; then
        apk_path=$(mktemp -d)/example.apk
        adb -s "$DEVICE_ID" pull "$device_apk" "$apk_path" >/dev/null
      fi
    fi
    if [ -n "$apk_path" ]; then
      echo "=== Installing prebuilt app on $dev ==="
      adb -s "$dev" install -r "$apk_path"
    else
      echo "warn: no prebuilt .apk found, building for $dev" >&2
      build_and_install "$dev"
    fi
  fi
}

if [ -n "$REBUILD" ] || ! app_installed "$DEVICE_ID"; then
  [ -n "$REBUILD" ] && echo "=== rebuild requested, building and installing ==="
  [ -z "$REBUILD" ] && echo "=== App ($BUNDLE_ID) not found, building and installing ==="
  build_and_install "$DEVICE_ID"
else
  echo "=== App ($BUNDLE_ID) already installed on $DEVICE_ID, skipping build ==="
fi

# Reuse the artifact built above for the remaining shard devices.
i=1
while [ "$i" -lt "${#DEVICES[@]}" ]; do
  dev="${DEVICES[$i]}"
  if [ -n "$REBUILD" ] || ! app_installed "$dev"; then
    install_prebuilt "$dev"
  else
    echo "=== App ($BUNDLE_ID) already installed on $dev, skipping install ==="
  fi
  i=$((i + 1))
done

EXTRA="--env SCREENSHOT_ROOT=$SCREENSHOT_ROOT"
[ -n "$UPDATE_SCREENSHOTS" ] && EXTRA="$EXTRA --env UPDATE_SCREENSHOTS=true"

# Exclude tests tagged for the other platform.
case "$PLATFORM" in
  ios)     EXTRA="$EXTRA --exclude-tags android-only" ;;
  android) EXTRA="$EXTRA --exclude-tags ios-only" ;;
esac

# Split flows across all shard devices. With --shard-split each flow still
# runs exactly once, so shared screenshot baselines stay safe.
DEVICE_ARGS="--device $DEVICE_IDS_CSV"
[ "$SHARDS" -gt 1 ] && DEVICE_ARGS="$DEVICE_ARGS --shard-split $SHARDS"

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
  # ANSI colors when piped through `tee`. It needs a real
  # terminal though, so skip it when there is none (e.g. CI).
  if ! [ -t 1 ]; then
    maestro test "$@" 2>&1 | tee "$tmp"
  elif [[ "$OSTYPE" == darwin* ]]; then
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
run_maestro $DEVICE_ARGS --exclude-tags accessibility $EXTRA $FLOWS
EXIT_REGULAR=$?

# These are the tests that require changing the system's settings
# - something maestro cannot run internally
echo "=== Running maestro accessibility tests ==="
set_font_scale large

# shellcheck disable=SC2086
run_maestro $DEVICE_ARGS --include-tags accessibility $EXTRA $FLOWS
EXIT_A11Y=$?

set -e

exit $(( EXIT_REGULAR != 0 || EXIT_A11Y != 0 ))
