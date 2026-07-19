# Snack Swap Adventure - Design Document

## Game Overview
A match-3 puzzle game with a snack + monster theme. Players feed cute monsters by matching snacks while dealing with obstacles.

## Key Screens & Wireframes

### Title Screen
- Big logo with mascot monster
- Primary CTA: Play
- Secondary: World Map, Monsters, Shop

### World Map
- Horizontal scrolling
- Worlds unlock progressively
- Level nodes with star ratings

### Gameplay HUD
- Top: Level + Moves + Goal progress
- Center: 8x8 grid
- Bottom: Pause + Boosters
- Side/Monster area: Animated monster face that reacts

### Level Complete / Fail
- Clear feedback
- Star rating animation
- Primary "Next" button

## Visual Style
- Bright, appetizing colors
- Cute, rounded monster designs
- Juicy animations (scale, particles, screen shake)
- Clear, readable fonts

## Special Tiles
| Match | Special Tile | Effect |
|-------|--------------|--------|
| 4 in row | Row Blaster | Clears row |
| 4 square | Popcorn Bomb | Area explosion |
| 5 in row | Rainbow Donut | Clears one type |
| L/T shape | Mega Munch | Big explosion + monster happy |

## Level Goals (Varied)
- Feed specific monster X snacks
- Break all chocolate/ice
- Drop items to bottom
- Clear sticky obstacles
- Rescue golden snacks

## Polish Priorities
1. Satisfying match feedback
2. Monster emotional reactions
3. Combo celebrations
4. Smooth tile animations

## Next Steps
- Build Version 1 prototype in SpriteKit
- Focus on core matching loop + basic animations first