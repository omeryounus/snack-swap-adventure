# Snack Swap Adventure

**A colorful match-3 puzzle game for iOS** where players match snacks to feed cute, hungry little monsters.

### Refined Concept
Players swap snacks to feed adorable monsters that react with personality. The game combines classic match-3 mechanics with emotional feedback and light progression.

**Core Loop**
- Swap neighboring snacks
- Match 3+ to feed monsters or clear obstacles
- Limited moves per level
- Special snacks (bombs, line clears, rainbow)
- Monsters react happily when fed well

### Unique Twists
- Monsters have emotions and react to combos
- Themed power-ups (Monster Snacks)
- Varied level goals (feed, break, rescue, clear)
- Light meta progression (unlock worlds + collect monsters)

## Tech Stack
- Swift + SpriteKit (recommended for iOS quality)
- SwiftUI for menus

## UI Wireframes

### 1. Title Screen
```
+------------------------------+
|          [Cute Monster]      |
|   Snack Swap Adventure       |
|                              |
|         [Play]               |
|                              |
|      [World Map]             |
|                              |
|   [Monsters]      [Shop]     |
+------------------------------+
```

### 2. World Map
```
+------------------------------+
| Cookie Kingdom          →   |
|                              |
| [1] [2] [3] [4] [5]        |
|  ★★★ ★★   ★★     ★     |
|                              |
| Popcorn Plains          →   |
+------------------------------+
```

### 3. Gameplay Screen (Core)
```
+----------------------------------+
| Level 12     Moves: 15   Goal: 30 |
| Feed Red Monster                 |
|                                  |
|   +----------------------+       |
|   |                      |       |
|   |     8x8 Snack Grid   |       |
|   |                      |       |
|   +----------------------+       |
|                                  |
| [Pause]   [Booster] [Booster]    |
|                                  |
|     [Happy Monster Face]         |
+----------------------------------+
```

### 4. Level Complete
```
+----------------------------------+
|         Level Complete!          |
|                                  |
|             ★ ★ ★             |
|                                  |
|         + 1,450 points           |
|                                  |
|         [Next Level]             |
|                                  |
|   [Replay]     [World Map]       |
+----------------------------------+
```

## Development Roadmap

### Phase 1: Core Prototype
- 8x8 grid + 6 snack types
- Swap + match detection + gravity
- Limited moves
- Basic juicy animations

### Phase 2: Special Tiles & Polish
- Line blaster, bomb, rainbow
- Monster reaction system
- Combo celebrations

### Phase 3: Content
- 30 levels with varied goals
- 4 worlds
- Monster collection

## Getting Started
See the detailed instructions in the previous version of this README or the DESIGN.md file.

**Let's build something fun and original!**