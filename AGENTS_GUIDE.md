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

## 📄 2. Essential Boilerplate Files & Responsibilities

When cloning this project, modify or reuse these core files:

### 📐 Layout Metrics & Device Sizing
- **File**: [`SnackSwapAdventure/Helpers/LayoutMetrics.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Helpers/LayoutMetrics.swift)
- **Purpose**: Provides dynamic sizing metrics based on device type (iPhone vs iPad) and safe area bounds.
- **Key Responsibilities**:
  - `isPad`: Detects if device is iPad (`UIDevice.current.userInterfaceIdiom == .pad`).
  - `boardMaxHeightRatio`: Reserves top HUD (`185pt` on iPhone, `220pt` on iPad) and bottom booster bar (`195pt` on iPhone, `240pt` on iPad) to prevent visual overlap.

### 🎨 Level Configuration & Per-Level Themes
- **File**: [`SnackSwapAdventure/Models/LevelConfig.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/LevelConfig.swift)
- **Purpose**: Defines per-level targets, move limits, theme names, color gradients, and snack item pools.
- **Key Pattern**:
  ```swift
  struct LevelTheme {
      let themeName: String
      let snacks: [SnackType]
      let bgColors: [Color]
      let boardFill: SKColor
      let boardStroke: SKColor
      
      static func forLevel(_ level: Int) -> LevelTheme {
          switch level {
          case 1:
              return LevelTheme(
                  themeName: "Warm Cookie Bakery",
                  snacks: [.cookie, .donut, .popcorn],
                  bgColors: [Color(hex: "663311"), Color(hex: "D97724")],
                  boardFill: SKColor(red: 0.28, green: 0.14, blue: 0.08, alpha: 0.92),
                  boardStroke: SKColor(Color(hex: "FF9E44"))
              )
          // ... 30 per-level theme definitions
          }
      }
  }
  ```

### 🎮 Match-3 Board Engine (SpriteKit)
- **File**: [`SnackSwapAdventure/Scenes/GameScene.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Scenes/GameScene.swift)
- **Purpose**: Core gameplay loop, touch gesture handling, swap validation, match-3 resolution, blaster creations, and drop gravity.
- **Critical Requirement**:
  - In `drawStageBackdrop()`, keep `backdrop.fillColor = .clear` so SwiftUI's animated background gradients shine through the SpriteKit view layer.

### 💾 Data Persistence & Star Synchronization
- **Files**:
  - [`SnackSwapAdventure/Models/PlayerProfile.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/PlayerProfile.swift)
  - [`SnackSwapAdventure/Models/MetaProgress.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Models/MetaProgress.swift)
- **Purpose**: Maintains player level progress, high scores, unlocked boosters, and star coin balances.
- **Cross-Sync Rule**: Mutating star balance in `PlayerProfile` must immediately sync `MetaProgress.shared` and `UserDefaults` (`ssa.stars` and `ssa.localStars`) to keep HUD counters in 100% sync.

### 🛍️ Monetization & Ads
- **StoreKit 2**: [`SnackSwapAdventure/Managers/StoreManager.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Managers/StoreManager.swift)
  - Product IDs: `com.snackswap.adventure.removeads`, `com.snackswap.adventure.stars100`, `com.snackswap.adventure.stars500`.
- **Google AdMob**: [`SnackSwapAdventure/Services/AdConfig.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Services/AdConfig.swift) and [`RewardedAdService.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Services/RewardedAdService.swift).
  - Pre-configured with Google's official Test Ad Unit IDs.

### ☁️ Cloud & Social Sync
- **Game Center**: [`SnackSwapAdventure/Managers/GameCenterManager.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Managers/GameCenterManager.swift)
- **iCloud Sync**: [`SnackSwapAdventure/Managers/iCloudSyncManager.swift`](file:///Users/omer/Documents/games/snack-swap-adventure/SnackSwapAdventure/SnackSwapAdventure/Managers/iCloudSyncManager.swift) (via `NSUbiquitousKeyValueStore`).

---

## 🚀 3. Step-by-Step Instructions to Clone for a New App

When creating a new game (e.g. *GemSwapQuest* or *FruitBurst*):

1. **Clone & Rename Project**:
   - Update Xcode Bundle Identifier (`com.yourcompany.newgame`).
   - Rename target and scheme in `.xcodeproj`.

2. **Update Item Pool (`SnackType.swift`)**:
   - Replace or extend the item enum (e.g. `case ruby, emerald, sapphire, diamond`).
   - Assign corresponding emojis, asset names, and base colors.

3. **Define New Per-Level Themes in `LevelConfig.swift`**:
   - Create 30+ level definitions with custom theme names, snack mixes, and background color gradients.

4. **Update StoreKit & AdMob Product IDs**:
   - Set product identifiers in `StoreManager.swift` matching App Store Connect IAPs.
   - Set production AdMob Ad Unit IDs in `AdConfig.swift`.

5. **Verify Sizing & Build**:
   - Build with `xcodebuild`.
   - Test on both iPhone (e.g., iPhone 16 Pro Max) and iPad (e.g., 13" iPad Pro) simulators.

6. **Generate App Store Screenshots**:
   - Run screenshot capture commands via `xcrun simctl io <device-id> screenshot <path.png>`.
   - Ensure App Store review screenshots follow Apple's exact required dimensions (6.9", 6.7", 6.5", 5.5", 13" iPad) in 24-bit RGB non-alpha format.
