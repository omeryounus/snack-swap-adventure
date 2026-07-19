# TestFlight Release Checklist

Snack Swap is configured to build as `com.snackswap.adventure` version `1.0` build `2`.

## Local Validation

Run a Release device build:

```sh
xcodebuild -project SnackSwapAdventure/SnackSwapAdventure.xcodeproj \
  -scheme SnackSwapAdventure \
  -configuration Release \
  -destination generic/platform=iOS \
  build
```

Create an archive after selecting an Apple Development Team in Xcode:

```sh
xcodebuild -project SnackSwapAdventure/SnackSwapAdventure.xcodeproj \
  -scheme SnackSwapAdventure \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath ./build/SnackSwapAdventure.xcarchive \
  archive
```

Upload/export with:

```sh
xcodebuild -exportArchive \
  -archivePath ./build/SnackSwapAdventure.xcarchive \
  -exportOptionsPlist SnackSwapAdventure/ExportOptions-AppStoreConnect.plist \
  -exportPath ./build/TestFlight
```

## App Store Connect Setup

- Create the app record for bundle ID `com.snackswap.adventure`.
- Set the target Signing & Capabilities team in Xcode.
- Create consumable IAPs with these product IDs:
  - `com.snackswap.adventure.stars60`
  - `com.snackswap.adventure.stars180`
  - `com.snackswap.adventure.stars500`
- Replace the Google sample AdMob app ID and rewarded ad unit before expecting ad revenue.
- Complete privacy answers for ads/tracking and in-app purchases.
- Add screenshots, description, keywords, support URL, and privacy policy URL.

## Notes

- Release builds disable simulated rewarded-ad fallback.
- The app includes an app privacy manifest for local `UserDefaults` usage.
- Google Mobile Ads and User Messaging Platform include their own privacy manifests through Swift Package Manager.
