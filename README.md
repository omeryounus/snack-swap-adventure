# Snack Swap Adventure

**A colorful match-3 puzzle game for iOS** — match snacks, feed monsters, climb the leaderboard.

## What’s included

### Gameplay
- 8×8 match-3 with 6 snack types
- Cascades, gravity, refill, juicy SFX
- **Specials**: row blaster, column blaster, bomb, rainbow (from 4+/5/L-T matches)
- **30 levels** across Cookie Kingdom, Popcorn Plains, Candy Canyon
- **Varied goals**: score, collect snack type, clear N snacks, make combos
- Pause menu with sound/music toggles
- Boosters shop + monster collection meta

### Backend (Vercel)
- Live API: **https://backend-deploy-sepia.vercel.app**
- Leaderboard, players, scores, global + player stats
- Durable-ready store (Upstash Redis optional + `/tmp` mirror)

## Run the iOS app

```bash
open SnackSwapAdventure/SnackSwapAdventure.xcodeproj
```

Or:

```bash
cd SnackSwapAdventure
xcodebuild -scheme SnackSwapAdventure \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Backend

### Deploy (CLI)

```bash
cd backend-deploy
./deploy.sh
# or:
npx vercel@latest --prod --yes --scope omeryounus-projects
```

### Optional Redis durability

Set on the Vercel project:

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
