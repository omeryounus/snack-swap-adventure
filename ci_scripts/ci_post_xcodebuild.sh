#!/bin/sh
# Fail the Xcode Cloud job if the archived app is still on the closed 1.0 train.
set -euo pipefail

if [ -z "${CI_ARCHIVE_PATH:-}" ] || [ ! -d "${CI_ARCHIVE_PATH}" ]; then
  echo "ci_post_xcodebuild: no archive path; skipping version check"
  exit 0
fi

PLIST="${CI_ARCHIVE_PATH}/Products/Applications/SnackSwapAdventure.app/Info.plist"
if [ ! -f "$PLIST" ]; then
  PLIST=$(find "$CI_ARCHIVE_PATH/Products" -name Info.plist -path "*.app/Info.plist" | head -1 || true)
fi

if [ -z "${PLIST:-}" ] || [ ! -f "$PLIST" ]; then
  echo "ci_post_xcodebuild: could not find app Info.plist in archive"
  exit 0
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
echo "ci_post_xcodebuild: archived ${VERSION} (${BUILD})"

if [ "$VERSION" = "1.0" ]; then
  echo "error: CFBundleShortVersionString is 1.0, but that App Store train is closed (ITMS-90186)."
  echo "Create version 1.1.1 in App Store Connect and point this Xcode Cloud workflow at 1.1.1."
  echo "Turn OFF 'Manage Version and Build Number' if Cloud is rewriting the plist back to 1.0."
  exit 1
fi

APP="${CI_ARCHIVE_PATH}/Products/Applications/SnackSwapAdventure.app"
if [ -d "$APP" ]; then
  TMP="${TMPDIR:-/tmp}/archived.entitlements"
  codesign -d --entitlements :- "$APP" > "$TMP" 2>/dev/null || true
  echo "ci_post_xcodebuild: archived entitlements:"
  cat "$TMP" || true
  if ! grep -q "com.apple.developer.game-center" "$TMP"; then
    echo "error: signed app is missing com.apple.developer.game-center"
    echo "Enable Game Center on the App ID and regenerate the distribution profile."
    exit 1
  fi
fi
