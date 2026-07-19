# Snack Swap Adventure — Backend API

Next.js API on **Vercel** for leaderboards and player stats.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/leaderboard?sort=&limit=` | Ranked players |
| GET | `/api/players` | All players + stats |
| POST | `/api/players` | Register / upsert player |
| GET | `/api/players/:id` | Single player |
| PATCH | `/api/players/:id` | Update name / avatar |
| POST | `/api/scores` | Submit level result |
| GET | `/api/scores` | Recent score events |
| GET | `/api/stats/global` | Aggregate stats |
| GET | `/api/stats/:playerId` | Player stats + rank |

### Submit score body

```json
{
  "playerId": "uuid",
  "displayName": "CookieQueen",
  "level": 12,
  "score": 4200,
  "stars": 3,
  "won": true,
  "movesLeft": 5,
  "maxCombo": 4
}
```

## Local dev

```bash
cd backend
npm install
npm run dev
```

## Deploy

Deployed via Vercel (project: `snack-swap-adventure-api`).
