# Snack Swap Adventure

A colorful match-3 puzzle game for iOS where players match delicious snacks to feed cute little monsters, break obstacles, and unlock fun new snack worlds.

**Theme**: Snacks + Cute Monsters
**Genre**: Match-3 Puzzle
**Platform**: iOS (Swift + SpriteKit)
**Goal**: Create a fun, polished, original match-3 experience inspired by the genre but with its own identity.

## Project Overview

This is an original match-3 game concept. We are **not** copying Candy Crush Saga. We are using the broad match-3 mechanics (swap tiles, match 3+, clear, gravity, limited moves) and building our own theme, art direction, special pieces, level goals, and progression.

### Core Gameplay Loop
1. Player swaps two neighboring snack tiles.
2. If 3+ same snacks align, they are eaten (cleared).
3. New snacks fall from the top.
4. Player has limited moves to complete the level goal.
5. Special snacks appear when matching 4 or 5 tiles.
6. Combos create powerful chain reactions.

### Unique Theme Elements
- **Snacks**: Cookies, popcorn, donuts, strawberries, pretzels, cupcakes
- **Monsters**: Cute, hungry little creatures that react when fed
- **Worlds**: Different snack-themed areas (Cookie Kingdom, Popcorn Plains, Donut Desert, etc.)
- **Obstacles**: Chocolate blocks, sticky honey, moving conveyor belts, locked treasure chests

## Tech Stack
- **Language**: Swift
- **Game Engine**: SpriteKit (native iOS, best performance and integration)
- **UI**: SwiftUI (for menus, level select, shop)
- **Recommended IDE**: Xcode 16+
- **Target**: iOS 17.0+

**Why SpriteKit?**
- Excellent performance on iOS
- Built-in particle effects and animations for juicy feedback
- Easy integration with Game Center, widgets, and App Intents
- Small app size
- Full control over every pixel and animation

## Getting Started (Step by Step)

### Prerequisites
- macOS with Xcode 16 or later installed
- Apple Developer account (free tier is enough to start)
- Basic knowledge of Swift and SpriteKit (or willingness to learn)

### Step 1: Create New SpriteKit Project
1. Open Xcode
2. File → New → Project
3. Choose **Game** template
4. Select **SpriteKit** as the Game Technology
5. Product Name: `SnackSwapAdventure`
6. Organization Identifier: `com.yourname` (or your own)
7. Interface: **SwiftUI**
8. Language: **Swift**
9. Game Technology: **SpriteKit**
10. Click Next → Create

### Step 2: Project Structure Recommendation
Create these folders inside your project:

```
SnackSwapAdventure/
├── Game/
│   ├── Scenes/
│   │   ├── GameScene.swift          # Main gameplay scene
│   │   └── MenuScene.swift
│   ├── Nodes/
│   │   ├── SnackTile.swift         # Individual tile node
│   │   └── MonsterNode.swift
│   └── Systems/
│       ├── BoardManager.swift      # Grid logic, matching, gravity
│       ├── MatchDetector.swift
│       └── LevelManager.swift
├── UI/
│   ├── Views/
│   │   ├── LevelSelectView.swift
│   │   └── GameHUD.swift
└── Resources/
    ├── Assets.xcassets/        # Snack textures, monster sprites, particles
    └── Sounds/
```

### Step 3: Basic GameScene Setup
Replace the content of `GameScene.swift` with a basic structure (see starter code below or in future commits).

### Step 4: Run the Project
1. Select your iPhone simulator or connected device
2. Press **Run** (Cmd + R)
3. You should see an empty SpriteKit scene

## Development Roadmap

### Version 1: Core Prototype (Focus on Fun First)
Goal: Get matching working with satisfying feedback.

Tasks:
- [ ] Create 8x8 grid
- [ ] 5-6 snack types with textures
- [ ] Implement tile swapping
- [ ] Detect 3+ matches in rows and columns
- [ ] Clear matched tiles with pop animation
- [ ] Implement gravity (tiles fall down)
- [ ] Refill empty spaces from top
- [ ] Add limited moves counter
- [ ] Basic win/lose condition
- [ ] Simple particle effects on match

### Version 2: Special Tiles & Combos
- [ ] Line blaster (match 4 in row)
- [ ] Snack bomb (match 4 in square)
- [ ] Rainbow donut (match 5)
- [ ] Combo system (multiple matches in one move)
- [ ] Juicy animations (scale, particles, screen shake, text popups like "Yum!" or "Crunch!")

### Version 3: 30 Levels + Progression
- [ ] Hand-designed levels with different goals
- [ ] New obstacles introduced gradually (crates, ice, honey, conveyors)
- [ ] Level select screen
- [ ] World map / progression

## Important Rules (Original Game)

- Do **not** copy Candy Crush art, name, sounds, or exact UI
- Create original snack designs and monster characters
- Design your own special tile visuals
- Make your own sound effects or use royalty-free
- Focus on "juicy" feedback (this is what makes match-3 addictive)

## Next Steps After Prototype
Once Version 1 works and feels fun:
1. Add special tiles and combos
2. Design first 10 levels
3. Add menus and level select
4. Implement light monetization (rewarded ads for extra moves)
5. Polish animations and sound

## Resources
- Apple SpriteKit Documentation: https://developer.apple.com/documentation/spritekit
- "Juicy" game feel articles (search for "game feel" + match-3)
- Free snack/monster asset sites (or create simple colored circles first for prototyping)

## License
This project is open for learning and personal use. Feel free to fork and experiment!

---

**Let's build something fun and original!** Start with Version 1 and focus on making the core matching loop feel satisfying.