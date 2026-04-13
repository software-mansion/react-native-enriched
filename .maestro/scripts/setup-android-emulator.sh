#!/bin/bash
set -euo pipefail

API_LEVEL="36"
DEVICE_ID="pixel_7"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  ABI="arm64-v8a"
else
  ABI="x86_64"
fi
TAG="google_apis_playstore"
SYSTEM_IMAGE="system-images;android-${API_LEVEL};${TAG};${ABI}"
AVD_NAME="Pixel7-API${API_LEVEL}-Enriched"
PORT=5570
SERIAL="emulator-${PORT}"

if [ -z "$ANDROID_HOME" ]; then
  echo "Error: ANDROID_HOME is not set. Set it to your Android SDK directory."
  exit 1
fi

# Ensure avdmanager and emulator use the same AVD directory regardless of
# what ANDROID_SDK_HOME is set to on the host (e.g. GitHub Actions runners).
export ANDROID_AVD_HOME="$HOME/.android/avd"
mkdir -p "$ANDROID_AVD_HOME"

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

if ! avdmanager list avd -c | grep -qx "${AVD_NAME}"; then
  echo "Creating AVD '$AVD_NAME'..."
  CREATE_CMD=(avdmanager create avd --name "$AVD_NAME" --device "$DEVICE_ID" --package "$SYSTEM_IMAGE")
  # Skin is cosmetic (phone frame). Skip it on CI since the runner has no skin files
  # and the emulator runs headless anyway.
  [ -z "${CI:-}" ] && CREATE_CMD+=(--skin "$DEVICE_ID")
  echo "no" | "${CREATE_CMD[@]}"
fi

AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$AVD_CONFIG" ]; then
  sed -i.bak 's/^hw\.keyboard=.*/hw.keyboard=yes/' "$AVD_CONFIG"
  grep -q "^hw.keyboard=" "$AVD_CONFIG" || echo "hw.keyboard=yes" >> "$AVD_CONFIG"
  sed -i.bak 's/^hw\.mainKeys=.*/hw.mainKeys=yes/' "$AVD_CONFIG"
  grep -q "^hw.mainKeys=" "$AVD_CONFIG" || echo "hw.mainKeys=yes" >> "$AVD_CONFIG"
  rm -f "$AVD_CONFIG.bak"
fi

if pgrep -f "emulator.*${AVD_NAME}" > /dev/null 2>&1; then
  echo "Emulator already running: $AVD_NAME ($SERIAL)"
  echo "DEVICE_ID=$SERIAL"
  exit 0
fi

echo "Starting emulator '$AVD_NAME'..."
EMULATOR_ARGS=("@${AVD_NAME}" -port "$PORT")
if [ -n "${CI:-}" ]; then
  EMULATOR_ARGS+=(-no-snapshot-save -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim)
fi

emulator "${EMULATOR_ARGS[@]}" > /dev/null 2>&1 &

echo "Waiting for emulator ($SERIAL) to connect to ADB..."
if ! timeout 120 adb -s "$SERIAL" wait-for-device; then
  echo "Error: Emulator did not connect to ADB after 120s."
  exit 1
fi

echo "Waiting for emulator to finish booting..."
until adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | grep -q "^1$"; do
  sleep 2
done

adb -s "$SERIAL" shell pm disable-user --user 0 com.google.android.inputmethod.latin

echo "Emulator ready: $AVD_NAME ($SERIAL)"
echo "DEVICE_ID=$SERIAL"
