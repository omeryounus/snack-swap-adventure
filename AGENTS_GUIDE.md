# 🤖 AGENTS & DEVELOPERS GUIDE: Match-3 Game Boilerplate Architecture

This document serves as an instruction manual for AI agents and human developers wishing to replicate, clone, or adapt the **Snack Swap Adventure** codebase to build new SwiftUI + SpriteKit grid/match-3 puzzle games for iOS and iPadOS.

---

## 🏗️ 1. Architecture Overview

The app follows a **hybrid SwiftUI + SpriteKit architecture**:
- **SwiftUI**: Outer container (`GameContainerView`), HUD (`GameHUD`), Booster Bar (`BoosterBarView`), Navigation, World Map (`WorldMapView`), Shop (`ShopView`), and Modals.
- **SpriteKit (`GameScene`)**: High-performance 2D match-3 grid physics, smooth swap/fall animations, cascade logic, particle effects, and board stroke rendering.

```
                  ┌──────────────────────────────────────────┐
                  │            ContentView (SwiftUI)         │
                  └────────────────────┬─────────────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                │          GameContainerView (SwiftUI)        │
                ├─────────────────────────────────────────────┤
                │  - GameplayBackgroundView (Vibrant Gradient)│
                │  - GameHUD (Top level badge & star count)   │
                │  - SpriteKit View (GameScene Host)          │
                │  - BoosterBarView (Bottom power-ups bar)    │
                └──────────────────────┬──────────────────────┘
                                       │
                  ┌────────────────────┴─────────────────────┐
                  │            GameScene (SpriteKit)         │
                  │  - 8x8 Tile Physics Grid                 │
                  │  - Match & Blaster Cascade Engine        │
                  │  - Transparent Backdrop Layer             │
                  └──────────────────────────────────────────┘
```

---

## 🛠️ 2. Comprehensive iOS Build & Required Setup Guide

When setting up or building the project from scratch, follow this exact environment setup checklist:

### A. Environment & Tools Checklist
| Component | Required Version | Notes / Installation Command |
|-----------|------------------|------------------------------|
| **macOS** | Sonoma 14.0+ / Sequoia 15.0+ | Mandatory for Xcode 15/16 |
| **Xcode** | Xcode 15.0+ / 16.0+ | Install from Mac App Store or Apple Developer Portal |
| **iOS SDK** | iOS 17.0+ | Include iPhone & iPad Simulator Runtimes |
| **CLI Tools** | Current | Run `xcode-select --install` in terminal |

### B. SPM Dependency Management
The project uses Swift Package Manager (SPM) integrated into `SnackSwapAdventure.xcodeproj`. The SPM dependencies are:
- `GoogleMobileAds`: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git` (v11.13.0+)
- `GoogleUserMessagingPlatform`: `https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git` (v2.7.0+)

**Command to resolve packages in headless CI or script mode**:
```bash
xcodebuild -project SnackSwapAdventure/SnackSwapAdventure.xcodeproj -resolvePackageDependencies
```

### C. Entitlements & Capabilities Configuration
1. **In-App Purchase**: StoreKit 2 configuration (`com.snackswap.adventure.removeads`, `com.snackswap.adventure.stars100`).
2. **iCloud Key-Value Store**: Enabled via `NSUbiquitousKeyValueStore` for syncing star balance, booster inventory, and completed levels across player devices.
3. **Game Center**: Active Game Center capability for reporting scores to global leaderboards.
4. **App Tracking Transparency**: Configured in `Info.plist` under `NSUserTrackingUsageDescription` for AdMob ad compliance.

---

## 🤖 3. GitHub Actions Automated CI/CD Workflow (`ios-build.yml`)

The repository includes a production-ready GitHub Actions workflow at [`.github/workflows/ios-build.yml`](file:///Users/omer/Documents/games/snack-swap-adventure/.github/workflows/ios-build.yml).

### A. How GitHub Actions CI Works
1. **Triggers**: Executed automatically on every `git push` to `main`/`master`, or manually via **Actions -> TestFlight -> Run workflow**.
2. **Environment**: Runs on `macos-26` runner with Xcode 15/16 pre-installed.
3. **Automated Signing**: Decodes `.p12` Distribution Certificate into an isolated runner keychain and uses `fastlane sigh` + App Store Connect API to generate matching mobileprovision profiles.
4. **TestFlight Deployment**: Archives `.xcarchive`, exports signed `.ipa`, uploads build to TestFlight using `xcrun altool`, and stores `.ipa` as a GitHub artifact.

### B. Required GitHub Secrets Setup
To enable CI/CD for cloned projects, set these secrets under GitHub Repository Settings -> **Secrets and variables -> Actions**:

```bash
# 1. Base64 encode your distribution certificate (.p12)
base64 -i cert.p12 -o cert_base64.txt

# 2. Base64 encode your App Store Connect API Key (.p8)
base64 -i AuthKey_8X9ABC.p8 -o asc_key_base64.txt
```

Add secrets to GitHub:
- `APPSTORE_API_KEY_ID`: Key ID from App Store Connect (e.g. `8X9ABC1234`).
- `APPSTORE_API_ISSUER_ID`: Issuer ID UUID from App Store Connect.
- `APPSTORE_API_KEY_BASE64`: Paste content of `asc_key_base64.txt`.
- `BUILD_CERTIFICATE_BASE64`: Paste content of `cert_base64.txt`.
- `P12_PASSWORD`: Password assigned to your `.p12` certificate.

---

## 📄 4. Essential Boilerplate Files & Responsibilities

When cloning this project, modify or reuse these core files:

### 📐 Layout Metrics & Device Sizing
- **File**: [`SnackSwapAdventure/Helpers/LayoutMetrics.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Helpers/LayoutMetrics.swift)
- **Purpose**: Provides dynamic sizing metrics based on device type (iPhone vs iPad) and safe area bounds.

### 🎨 Level Configuration & Per-Level Themes
- **File**: [`SnackSwapAdventure/Models/LevelConfig.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/LevelConfig.swift)
- **Purpose**: Defines per-level targets, move limits, theme names, color gradients, and snack item pools.

### 🎮 Match-3 Board Engine (SpriteKit)
- **File**: [`SnackSwapAdventure/Scenes/GameScene.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Scenes/GameScene.swift)
- **Purpose**: Core gameplay loop, touch gesture handling, swap validation, match-3 resolution, blaster creations, and drop gravity.

### 💾 Data Persistence & Star Synchronization
- **Files**:
  - [`SnackSwapAdventure/Models/PlayerProfile.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/PlayerProfile.swift)
  - [`SnackSwapAdventure/Models/MetaProgress.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/MetaProgress.swift)

### 🛍️ Monetization & Ads
- **StoreKit 2**: [`SnackSwapAdventure/Managers/StoreManager.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Managers/StoreManager.swift)
- **Google AdMob**: [`SnackSwapAdventure/Services/AdConfig.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Services/AdConfig.swift) and [`RewardedAdService.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Services/RewardedAdService.swift).

---

## 🚀 5. Step-by-Step Instructions to Clone for a New App

1. **Clone & Rename Project**: Update Xcode Bundle Identifier (`com.yourcompany.newgame`) and scheme.
2. **Update Item Pool (`SnackType.swift`)**: Replace/extend item enums and emoji icons.
3. **Define Themes in `LevelConfig.swift`**: Create 30+ level definitions with custom theme names and snack pools.
4. **Setup GitHub Secrets**: Add the 5 required repository secrets for automated GitHub Actions TestFlight builds.
5. **Verify Sizing & Build**: Test on iPhone and iPad simulators using `xcodebuild` and `xcrun simctl`.
6. **Generate Screenshots**: Capture exact App Store & IAP review screenshots (6.9", 6.5", 5.5", 13" iPad).
