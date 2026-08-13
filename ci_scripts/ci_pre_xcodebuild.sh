#!/bin/sh
# Xcode Cloud: force a marketing version higher than the closed 1.0 train.
# App Store Connect rejects CFBundleShortVersionString 1.0 (ITMS-90186 / ITMS-90062).
set -euo pipefail

MARKETING_VERSION="1.1"
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJ_DIR="$ROOT/SnackSwapAdventure"
INFO="$PROJ_DIR/Info.plist"

echo "ci_pre_xcodebuild: pinning CFBundleShortVersionString to ${MARKETING_VERSION}"

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
