#!/bin/sh
# Xcode Cloud: pin marketing version and confirm Game Center entitlements exist.
set -euo pipefail

MARKETING_VERSION="1.2"
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJ_DIR="$ROOT/SnackSwapAdventure"
INFO="$PROJ_DIR/Info.plist"
ENTITLEMENTS="$PROJ_DIR/SnackSwapAdventure/SnackSwapAdventure.entitlements"

echo "ci_pre_xcodebuild: pinning CFBundleShortVersionString to ${MARKETING_VERSION}"

if [ ! -f "$ENTITLEMENTS" ]; then
  echo "error: missing $ENTITLEMENTS"
  exit 1
fi
if ! grep -q "com.apple.developer.game-center" "$ENTITLEMENTS"; then
  echo "error: $ENTITLEMENTS is missing com.apple.developer.game-center"
  exit 1
fi
echo "ci_pre_xcodebuild: Game Center entitlement file OK"

if [ -d "$PROJ_DIR/SnackSwapAdventure.xcodeproj" ]; then
  (
    cd "$PROJ_DIR"
    xcrun agvtool new-marketing-version "$MARKETING_VERSION" || true
  )
fi

if [ -f "$INFO" ]; then
  if /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MARKETING_VERSION" "$INFO"
  else
    /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $MARKETING_VERSION" "$INFO"
  fi
fi
