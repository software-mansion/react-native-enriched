#!/bin/bash
# setup-android-emulator.sh - boot one or more Android emulator instances.
#
# Usage:
#   ./setup-android-emulator.sh [num_devices]
#
# Boots `num_devices` (default 1) independent emulators.
# Prints:
#   DEVICE_ID=<first serial>
#   DEVICE_IDS=<comma-separated serials>
set -euo pipefail

NUM_DEVICES="${1:-1}"
if ! [[ "$NUM_DEVICES" =~ ^[0-9]+$ ]] || [ "$NUM_DEVICES" -lt 1 ]; then
  echo "Error: num_devices must be a positive integer (got '$NUM_DEVICES')" >&2
  exit 1
fi

API_LEVEL="36"
DEVICE_ID="pixel_9"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  ABI="arm64-v8a"
else
  ABI="x86_64"
fi
TAG="google_apis_playstore"
SYSTEM_IMAGE="system-images;android-${API_LEVEL};${TAG};${ABI}"
AVD_BASE="Pixel9-API${API_LEVEL}-Enriched"
BASE_PORT=5570

if [ -z "${ANDROID_HOME:-}" ]; then
  echo "Error: ANDROID_HOME is not set. Set it to your Android SDK directory."
  exit 1
fi

for tool in sdkmanager avdmanager emulator adb; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: '$tool' not found. Ensure Android SDK tools are installed and in PATH."
    exit 1
  fi
done

yes | sdkmanager --licenses > /dev/null 2>&1 || true

if ! sdkmanager --list_installed 2>/dev/null | grep -q "system-images;android-${API_LEVEL};"; then
  echo "Installing system image '$SYSTEM_IMAGE'..."
  sdkmanager "$SYSTEM_IMAGE"
fi

if ! avdmanager list device -c | grep -qx "$DEVICE_ID"; then
  echo "Error: Device definition '$DEVICE_ID' not found."
  exit 1
fi

configure_avd() {
  local avd_name="$1"
  local avd_config="$HOME/.android/avd/${avd_name}.avd/config.ini"
  if [ -f "$avd_config" ]; then
    sed -i '' 's/^hw\.keyboard=.*/hw.keyboard=yes/' "$avd_config"
    grep -q "^hw.keyboard=" "$avd_config" || echo "hw.keyboard=yes" >> "$avd_config"
    sed -i '' 's/^hw\.mainKeys=.*/hw.mainKeys=yes/' "$avd_config"
    grep -q "^hw.mainKeys=" "$avd_config" || echo "hw.mainKeys=yes" >> "$avd_config"
  fi
}

SERIALS=()
AVD_NAMES=()
i=0
while [ "$i" -lt "$NUM_DEVICES" ]; do
  # Each shard gets its own numbered AVD so they boot fully independently.
  if [ "$i" -eq 0 ]; then
    AVD_NAME="$AVD_BASE"
  else
    AVD_NAME="${AVD_BASE}-$((i + 1))"
  fi
  PORT=$((BASE_PORT + 2 * i))
  SERIAL="emulator-${PORT}"
  SERIALS+=("$SERIAL")
  AVD_NAMES+=("$AVD_NAME")

  if ! avdmanager list avd -c | grep -qx "$AVD_NAME"; then
    echo "Creating AVD '$AVD_NAME'..."
    echo "no" | avdmanager create avd \
      --name "$AVD_NAME" \
      --device "$DEVICE_ID" \
      --package "$SYSTEM_IMAGE" \
      --skin "$DEVICE_ID"
  fi
  configure_avd "$AVD_NAME"

  if adb -s "$SERIAL" get-state >/dev/null 2>&1; then
    echo "Emulator already running: $AVD_NAME ($SERIAL)"
  else
    echo "Starting emulator '$AVD_NAME' ($SERIAL)..."
    emulator "@${AVD_NAME}" -port "$PORT" -no-boot-anim -no-snapshot-save > /dev/null 2>&1 &
  fi
  i=$((i + 1))
done

for idx in "${!SERIALS[@]}"; do
  SERIAL="${SERIALS[$idx]}"
  AVD_NAME="${AVD_NAMES[$idx]}"

  echo "Waiting for emulator ($SERIAL) to connect to ADB..."
  if ! timeout 120 adb -s "$SERIAL" wait-for-device; then
    echo "Error: Emulator $SERIAL did not connect to ADB after 120s."
    exit 1
  fi

  echo "Waiting for emulator ($SERIAL) to finish booting..."
  until adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | grep -q "^1$"; do
    sleep 2
  done

  adb -s "$SERIAL" shell pm disable-user --user 0 com.google.android.inputmethod.latin
  adb -s "$SERIAL" shell settings put secure spell_checker_enabled 0

  # Disable system animations so taps/transitions settle instantly and
  # waitForAnimationToEnd doesn't pay real animation time.
  adb -s "$SERIAL" shell settings put global window_animation_scale 0
  adb -s "$SERIAL" shell settings put global transition_animation_scale 0
  adb -s "$SERIAL" shell settings put global animator_duration_scale 0

  echo "Emulator ready: $AVD_NAME ($SERIAL)"
done

DEVICE_IDS=$(IFS=,; echo "${SERIALS[*]}")
echo "DEVICE_ID=${SERIALS[0]}"
echo "DEVICE_IDS=$DEVICE_IDS"
