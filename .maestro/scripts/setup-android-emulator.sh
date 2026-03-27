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

# Pixel 9 screen specs injected into config.ini only when the native profile isn't available.
PIXEL_9_LCD_WIDTH="1080"
PIXEL_9_LCD_HEIGHT="2424"
PIXEL_9_LCD_DENSITY="422"

AVD_DEVICE_PROFILE="$DEVICE_ID"
PATCH_PIXEL9_DIMENSIONS=""
if ! avdmanager list device -c | grep -qx "$DEVICE_ID"; then
  AVD_DEVICE_PROFILE="pixel_7"
  PATCH_PIXEL9_DIMENSIONS="true"
  if ! avdmanager list device -c | grep -qx "$AVD_DEVICE_PROFILE"; then
    echo "Error: Neither '$DEVICE_ID' nor fallback '$AVD_DEVICE_PROFILE' device definition found."
    exit 1
  fi
  echo "Warning: '$DEVICE_ID' not found, using '$AVD_DEVICE_PROFILE' as base and patching Pixel 9 screen dimensions."
fi

if ! avdmanager list avd -c | grep -qx "${AVD_NAME}"; then
  echo "Creating AVD '$AVD_NAME'..."
  CREATE_CMD=(avdmanager create avd --name "$AVD_NAME" --device "$AVD_DEVICE_PROFILE" --package "$SYSTEM_IMAGE")
  [ -z "$PATCH_PIXEL9_DIMENSIONS" ] && CREATE_CMD+=(--skin "$DEVICE_ID")
  echo "no" | "${CREATE_CMD[@]}"
fi

AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$AVD_CONFIG" ]; then
  sed -i.bak 's/^hw\.keyboard=.*/hw.keyboard=yes/' "$AVD_CONFIG"
  grep -q "^hw.keyboard=" "$AVD_CONFIG" || echo "hw.keyboard=yes" >> "$AVD_CONFIG"
  sed -i.bak 's/^hw\.mainKeys=.*/hw.mainKeys=yes/' "$AVD_CONFIG"
  grep -q "^hw.mainKeys=" "$AVD_CONFIG" || echo "hw.mainKeys=yes" >> "$AVD_CONFIG"
  # Only patch screen dimensions when using the fallback profile; the native pixel_9
  # profile already sets the correct values via the skin.
  if [ -n "$PATCH_PIXEL9_DIMENSIONS" ]; then
    sed -i.bak "s/^hw\.lcd\.width=.*/hw.lcd.width=${PIXEL_9_LCD_WIDTH}/" "$AVD_CONFIG"
    grep -q "^hw.lcd.width=" "$AVD_CONFIG" || echo "hw.lcd.width=${PIXEL_9_LCD_WIDTH}" >> "$AVD_CONFIG"
    sed -i.bak "s/^hw\.lcd\.height=.*/hw.lcd.height=${PIXEL_9_LCD_HEIGHT}/" "$AVD_CONFIG"
    grep -q "^hw.lcd.height=" "$AVD_CONFIG" || echo "hw.lcd.height=${PIXEL_9_LCD_HEIGHT}" >> "$AVD_CONFIG"
    sed -i.bak "s/^hw\.lcd\.density=.*/hw.lcd.density=${PIXEL_9_LCD_DENSITY}/" "$AVD_CONFIG"
    grep -q "^hw.lcd.density=" "$AVD_CONFIG" || echo "hw.lcd.density=${PIXEL_9_LCD_DENSITY}" >> "$AVD_CONFIG"
  fi
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

if [ -n "${CI:-}" ]; then
  emulator "${EMULATOR_ARGS[@]}" > /tmp/emulator.log 2>&1 &
else
  emulator "${EMULATOR_ARGS[@]}" > /dev/null 2>&1 &
fi

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
