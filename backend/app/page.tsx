import { getGlobalStats, getLeaderboard } from "@/lib/store";
import type { LeaderboardSort } from "@/lib/types";
import { LeaderboardClient } from "./leaderboard-client";

export const dynamic = "force-dynamic";

export default function HomePage() {
  const global = getGlobalStats();
  const initial = getLeaderboard("highScore", 50);

  return (
    <main>
      <section className="hero">
        <div className="mascot">👾</div>
        <h1>Snack Swap Adventure</h1>
        <p>Live leaderboard & player stats API</p>
      </section>

      <section className="grid">
        <div className="stat-card">
          <div className="label">Players</div>
          <div className="value">{global.totalPlayers}</div>
        </div>
        <div className="stat-card">
          <div className="label">Games Played</div>
          <div className="value">{global.totalGamesPlayed}</div>
        </div>
        <div className="stat-card">
          <div className="label">Top Score</div>
          <div className="value">{global.topScore.toLocaleString()}</div>
        </div>
        <div className="stat-card">
          <div className="label">Champion</div>
          <div className="value" style={{ fontSize: "1.1rem" }}>
            {global.topPlayerName ?? "—"}
          </div>
        </div>
      </section>

      <LeaderboardClient initialEntries={initial} initialSort={"highScore" as LeaderboardSort} />

      <section className="panel">
        <h2>API</h2>
        <div className="api-box">{`GET  /api/health
GET  /api/leaderboard?sort=highScore|totalScore|highestLevel|totalStars|wins|maxCombo&limit=50
GET  /api/players
POST /api/players           { displayName, playerId?, avatarEmoji? }
GET  /api/players/:id
PATCH /api/players/:id      { displayName?, avatarEmoji? }
POST /api/scores            { playerId, displayName?, level, score, stars, won, movesLeft, maxCombo }
GET  /api/scores?limit=20
GET  /api/stats/global
GET  /api/stats/:playerId`}</div>
      </section>

      <footer>Built for the Snack Swap Adventure iOS game · Hosted on Vercel</footer>
    </main>
  );
}
