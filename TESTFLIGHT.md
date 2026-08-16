# TestFlight Release Checklist

Snack Swap is configured to build as `com.snackswap.adventure` version `1.3`.
Closed trains on App Store Connect: **1.0**, **1.1**, **1.1.1**, **1.2**. New binaries must ship `CFBundleShortVersionString` **1.3 or higher**.

Before the next Xcode Cloud / TestFlight upload:

1. In App Store Connect, create version **1.3**.
2. Point the Archive workflow at **1.3** and turn **off** “Manage Version and Build Number”.
3. Confirm App ID `com.snackswap.adventure` has **Game Center** enabled.

## Where the version lives

The marketing version is duplicated in four places, and the CI copies **overwrite**
the project at build time — bumping only the project ships the old version:

| Location | Effect |
|---|---|
| `ci_scripts/ci_pre_xcodebuild.sh` | Xcode Cloud: rewrites Info.plist + runs `agvtool`. **Wins.** |
| `.github/workflows/ios-build.yml` | GitHub Actions: passes `MARKETING_VERSION` to `xcodebuild`. **Wins.** |
| `SnackSwapAdventure/Info.plist` | Source of truth for local archives only. |
| `project.pbxproj` (`MARKETING_VERSION`) | Source of truth for local archives only. |

Bump all four together, and add the retired version to the closed-train guards in
both `ci_scripts/ci_post_xcodebuild.sh` and the GitHub workflow.

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
