#!/bin/bash
set -euo pipefail

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
AVD_NAME="Pixel9-API${API_LEVEL}-Enriched"
PORT=5570
SERIAL="emulator-${PORT}"

if [ -z "$ANDROID_HOME" ]; then
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

if ! avdmanager list avd -c | grep -qx "${AVD_NAME}"; then
  echo "Creating AVD '$AVD_NAME'..."
  echo "no" | avdmanager create avd \
    --name "$AVD_NAME" \
    --device "$DEVICE_ID" \
    --package "$SYSTEM_IMAGE" \
    --skin "$DEVICE_ID"
fi

AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$AVD_CONFIG" ]; then
  sed -i '' 's/^hw\.keyboard=.*/hw.keyboard=yes/' "$AVD_CONFIG"
  grep -q "^hw.keyboard=" "$AVD_CONFIG" || echo "hw.keyboard=yes" >> "$AVD_CONFIG"
  sed -i '' 's/^hw\.mainKeys=.*/hw.mainKeys=yes/' "$AVD_CONFIG"
  grep -q "^hw.mainKeys=" "$AVD_CONFIG" || echo "hw.mainKeys=yes" >> "$AVD_CONFIG"
fi

if pgrep -f "emulator.*${AVD_NAME}" > /dev/null 2>&1; then
  echo "Emulator already running: $AVD_NAME ($SERIAL)"
  echo "DEVICE_ID=$SERIAL"
  exit 0
fi

echo "Starting emulator '$AVD_NAME'..."
emulator "@${AVD_NAME}" -port "$PORT" > /dev/null 2>&1 &

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
