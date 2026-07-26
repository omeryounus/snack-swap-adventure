# Snack Swap Adventure

**A premium, colorful match-3 puzzle game for iOS & iPadOS** — match snacks, activate explosive special combos, collect adorable monsters, sync progress across devices, and climb global leaderboards!

![Snack Swap Adventure Banner](AppStore_Screenshots/6.9_Inch_iPhone_16_Pro_Max/03_Match3_Gameplay.png)

---

## 🌟 Key Features

### 🎮 Gameplay & Level Mechanics
- **8×8 Match-3 Engine**: Built with SwiftUI + SpriteKit for high-performance 60fps animations, physics cascades, gravity refills, and juicy visual effects.
- **30 Unique Per-Level Themes**: Every single level (1–30) features distinct vibrant background gradient palettes (*Warm Cookie Bakery*, *Donut Dreamland*, *Glacier Ice Candy*, *Electric Purple Lagoon*, *Deep Cosmic Sapphire*), customized board stroke colors, and theme badges.
- **Dynamic Snack Item Mixes**: Levels cycle through custom combinations of 12 distinct snack types (Cookies, Donuts, Popcorn, Candy Canes, Lollipops, Cupcakes, Gummy Bears, Croissants, Chocolate Bars, Tacos, Boba, and Ice Cream Cones).
- **Special Blasters & Combos**:
  - 4-in-a-row/column: Row Blaster / Column Blaster
  - 5-in-a-T/L shape: Snack Bomb (clears 3x3 area)
  - 5-in-a-line: Rainbow Snack (clears all snacks of a selected color)
- **Varied Level Goals**: Target score, specific snack collection, obstacle clearing, and special combo creation within move limits.

### 📱 Universal Device & Layout Sizing
- **Dynamic Sizing System (`LayoutMetrics.swift`)**: Seamless layout adaptation for all iPhone models (5.5" to 6.9") and all iPad models (Mini, Air, 11", 13" iPad Pro).
- **Aspect Ratio Sizing**: SpriteKit board dynamically scales to fill available screen height while preserving safe-area margins for HUD pills and booster toolbars.

### 💰 Monetization & Social Features
- **In-App Purchases (`StoreManager.swift`)**: StoreKit 2 integration for purchasing star coin packs and Permanent Ad Removal (`com.snackswap.adventure.removeads`).
- **Google AdMob Integration (`AdConfig.swift`, `RewardedAdService.swift`)**:
  - Banner Ads, Interstitial Ads between levels, and Rewarded Video Ads for free extra moves & boosters.
  - Test Ad IDs pre-configured for safe development.
- **Game Center Leaderboards (`GameCenterManager.swift`)**: Real-time high-score submission and leaderboard browsing.
- **iCloud Sync (`iCloudSyncManager.swift`)**: Automatic cloud persistence for level progress, star balances, and unlocked boosters across iOS & iPadOS devices.
- **Daily Rewards System (`DailyRewardsManager.swift`)**: 7-day streak rewards with dynamic star bonuses.

### 🌐 Backend API (Vercel + Next.js)
- **Live Production Endpoint**: `https://backend-deploy-sepia.vercel.app`
- **Endpoints**:
  - `GET /api/health` — Health check
  - `GET /api/leaderboard?sort=&limit=` — Fetch top global rankings
  - `POST /api/scores` — Submit level score
  - `GET/POST /api/players` — Manage player profiles
  - `GET /api/stats/global` — Global gameplay statistics
- **Durable Storage**: Upstash Redis integration with automatic `/tmp` fallback for zero-downtime execution.

---

## 📂 Project Architecture

```
snack-swap-adventure/
├── SnackSwapAdventure/           # Main iOS Application Project
│   ├── SnackSwapAdventure/
│   │   ├── App/                  # App Entry, Theme tokens, Content View
│   │   ├── Models/               # LevelConfig, GameState, PlayerProfile, MetaProgress, SnackType
│   │   ├── Scenes/               # GameScene (SpriteKit physics, grid rendering, cascades)
│   │   ├── Views/                # SwiftUI UI System, GameHUD, BoosterBar, WorldMap, StoreView
│   │   ├── Managers/             # StoreManager, GameCenterManager, iCloudSyncManager, SoundManager
│   │   ├── Services/             # AdConfig, RewardedAdService, VoiceAnnouncer
│   │   └── Helpers/              # LayoutMetrics (Responsive iPad & iPhone layout engine)
├── AppStore_Screenshots/         # App Store Showcase Screenshots (6.9", 6.5", 5.5" iPhone, 13" iPad)
├── IAP_Review_Screenshots/       # Apple IAP Review Compliant Screenshots (24-bit RGB non-alpha)
├── AGENTS_GUIDE.md               # Complete AI Agent & Developer Cloning Instruction Guide
├── backend-deploy/               # Vercel Production API Deployment
└── README.md
```

---

## 🛠️ Comprehensive iOS Build & Required Setup Guide

### 📋 1. System & Developer Prerequisites
- **macOS**: macOS Sonoma 14.0 or macOS Sequoia 15.0+
- **Xcode**: Xcode 15.0+ or Xcode 16.0+ (with iOS 17.0+ Simulator SDKs)
- **Swift Command Line Tools**: `xcode-select --install`
- **Apple Developer Account**: Required for device deployment, In-App Purchase configuration, Game Center, and App Store Connect uploading.

---

### 📦 2. Swift Package Dependencies
The project relies on Swift Package Manager (SPM) for external SDK dependencies. Packages resolve automatically upon opening in Xcode:
- **GoogleMobileAds**: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git` (v11.13.0+)
- **GoogleUserMessagingPlatform**: `https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git` (v2.7.0+)

To resolve dependencies manually via terminal:
```bash
cd SnackSwapAdventure
xcodebuild -resolvePackageDependencies
```

---

### ⚙️ 3. Xcode Target & Entitlements Configuration

#### A. General & Deployment Info
- **Bundle Identifier**: `com.snackswap.adventure`
- **Minimum Deploy Target**: iOS 17.0
- **Supported Devices**: iPhone & iPad (Universal Target)
- **Supported Orientations**: Portrait (iPhone & iPad)

#### B. Signing & Capabilities
In Xcode under **Target -> Signing & Capabilities**, ensure the following capabilities are enabled:
1. **In-App Purchase**: StoreKit 2 entitlement.
2. **iCloud**: Key-Value Storage enabled (`NSUbiquitousKeyValueStore`).
3. **Game Center**: Enable Game Center capability for leaderboard score submission.

#### C. `Info.plist` Privacy & AdMob Keys
The `Info.plist` includes essential keys for Google AdMob and privacy disclosures:
- `GADApplicationIdentifier`: `ca-app-pub-3940256099942544~3347511713` (Google AdMob Test App ID)
- `NSUserTrackingUsageDescription`: Permission text requested for personalized ads via App Tracking Transparency.
- `SKAdNetworkItems`: Pre-configured list of AdMob ad network identifier keys.

---

### 🚀 4. Building & Running the Project

#### Option A: Running via Xcode Interface (GUI)
1. Open the project:
   ```bash
   open SnackSwapAdventure/SnackSwapAdventure.xcodeproj
   ```
2. Select your target scheme: **SnackSwapAdventure**.
3. Choose a destination (e.g. **iPhone 16**, **iPhone 16 Pro Max**, or **iPad Pro 13-inch (M4)**).
4. Press `Cmd + R` to build and run.

#### Option B: Building via Terminal (`xcodebuild`)
To build for iOS Simulator from the terminal:
```bash
cd SnackSwapAdventure

# List available simulator destination IDs
xcrun simctl list devices available | grep iPhone

# Build for specific Simulator ID
xcodebuild -project SnackSwapAdventure.xcodeproj \
  -scheme SnackSwapAdventure \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=8AFC8E25-62D0-4A8F-A52A-41F69D0B37A5' build
```

#### Option C: Installing & Launching on Simulator via CLI
```bash
# Install app bundle onto running Simulator
xcrun simctl install 8AFC8E25-62D0-4A8F-A52A-41F69D0B37A5 \
  ~/Library/Developer/Xcode/DerivedData/SnackSwapAdventure-*/Build/Products/Debug-iphonesimulator/SnackSwapAdventure.app

# Launch app
xcrun simctl launch 8AFC8E25-62D0-4A8F-A52A-41F69D0B37A5 com.snackswap.adventure
```

---

### 📦 5. Archiving & Publishing to App Store Connect / TestFlight

#### Step 1: Create an Archive
```bash
cd SnackSwapAdventure
xcodebuild -project SnackSwapAdventure.xcodeproj \
  -scheme SnackSwapAdventure \
  -configuration Release \
  -archivePath build/SnackSwapAdventure.xcarchive archive
```

#### Step 2: Upload to App Store Connect
1. Open Xcode -> **Window -> Organizer** (`Cmd + Option + Shift + O`).
2. Select the **SnackSwapAdventure** archive.
3. Click **Distribute App** -> **App Store Connect** -> **Upload**.
4. Select your Development Team and complete validation.

---

## 📸 App Store Screenshots & Assets

Automated screenshot generator script generates exact pixel-dimension showcase sets:
- **6.9" iPhone 16 Pro Max**: 1320 × 2868 px
- **6.5" iPhone 15 Pro Max**: 1290 × 2796 px
- **5.5" iPhone 8 Plus**: 1242 × 2208 px
- **13" iPad Pro**: 2048 × 2732 px
- **In-App Purchase Review**: 1260 × 2736 px (24-bit RGB non-alpha format)

---

## 🤖 Replicating / Cloning This App

For building new match-3 games or cloning this architecture, follow the
complete step-by-step instructions in [AGENTS_GUIDE.md](AGENTS_GUIDE.md).

- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

Without them, the API uses in-memory + `/tmp` mirroring (fine for demos; multi-instance needs Redis).

### API

| Method | Path |
|--------|------|
| GET | `/api/health` |
| GET | `/api/leaderboard?sort=&limit=` |
| GET/POST | `/api/players` |
| GET/PATCH | `/api/players/:id` |
| GET/POST | `/api/scores` |
| GET | `/api/stats/global` |
| GET | `/api/stats/:playerId` |

## Project layout

```
SnackSwapAdventure/     iOS (SwiftUI + SpriteKit)
backend-deploy/         Production Vercel app (JS)
backend/                TypeScript source / local Next dev
DESIGN.md
```

## Devices & orientations

The SwiftUI + SpriteKit UI now scales across iPhone SE through iPhone Pro Max and iPad Mini through iPad Pro (12.9"), including Split View. Portrait and landscape are both supported:

- **Portrait** — top HUD, centered 8×8 board, boosters + mascot along the bottom
- **Landscape** — left sidebar (HUD, boosters, mascot) so the board stays large enough to tap
- **iPad** — centered content width, extra grid columns, larger tiles (capped so they don't balloon)
- Menus, overlays, and the daily-reward sheet scroll when height is tight

## How to play

1. **Play** or pick a level on the **World Map**
2. Swap adjacent snacks to make matches of 3+
3. Complete the **level goal** before moves run out
4. Earn coins → **Shop** boosters; unlock **Monsters**
5. Climb the online **Ranks** board

## Roadmap status

| Phase | Status |
|-------|--------|
| 1 Core prototype | ✅ |
| 2 Specials & polish | ✅ |
| 3 Content (30 levels, monsters, shop) | ✅ |
| Online leaderboard + stats | ✅ |
| Durable Redis (optional env) | ✅ wired |
| Hand-painted art pack | Optional next |
| App Store packaging | Optional next |
