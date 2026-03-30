#!/bin/bash
set -euo pipefail

DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17"
IOS_VERSION="26.2"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-$(echo "$IOS_VERSION" | tr '.' '-')"
RUNTIME_LABEL="iOS $IOS_VERSION"
DEVICE_NAME="iPhone17-iOS${IOS_VERSION}-Enriched"

if ! xcrun simctl list runtimes | grep -q "$RUNTIME"; then
  echo "Error: $RUNTIME_LABEL runtime not found."
  echo "Install it in Xcode."
  exit 1
fi

if ! xcrun simctl list devices | grep -q "$DEVICE_NAME ("; then
  echo "Creating simulator '$DEVICE_NAME'..."
  xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME"
fi

UDID=$(xcrun simctl list devices | grep "$DEVICE_NAME (" | head -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$UDID" ]; then
  echo "Error: Could not find UDID for '$DEVICE_NAME'"
  exit 1
fi

STATE=$(xcrun simctl list devices | grep "$UDID" | grep -oE '\(Booted\)|\(Shutdown\)' || true)
if [ "$STATE" != "(Booted)" ]; then
  echo "Booting '$DEVICE_NAME' ($UDID)..."
  xcrun simctl boot "$UDID"
fi

if [ -z "${CI:-}" ]; then
  open -a Simulator
fi

echo "Simulator ready: $DEVICE_NAME ($UDID)"
echo "DEVICE_ID=$UDID"
