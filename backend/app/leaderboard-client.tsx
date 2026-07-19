"use client";

import { useState } from "react";
import type { LeaderboardEntry, LeaderboardSort } from "@/lib/types";

const SORTS: { key: LeaderboardSort; label: string }[] = [
  { key: "highScore", label: "High Score" },
  { key: "totalScore", label: "Total Score" },
  { key: "highestLevel", label: "Level" },
  { key: "totalStars", label: "Stars" },
  { key: "wins", label: "Wins" },
  { key: "maxCombo", label: "Max Combo" },
];

export function LeaderboardClient({
  initialEntries,
  initialSort,
}: {
  initialEntries: LeaderboardEntry[];
  initialSort: LeaderboardSort;
}) {
  const [sort, setSort] = useState<LeaderboardSort>(initialSort);
  const [entries, setEntries] = useState(initialEntries);
  const [loading, setLoading] = useState(false);

  async function changeSort(next: LeaderboardSort) {
    setSort(next);
    setLoading(true);
    try {
      const res = await fetch(`/api/leaderboard?sort=${next}&limit=50`, {
        cache: "no-store",
      });
      const data = await res.json();
      setEntries(data.entries || []);
    } catch {
      // keep current
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="panel">
      <h2>🏆 Leaderboard {loading ? "…" : ""}</h2>
      <div className="tabs">
        {SORTS.map((s) => (
          <button
            key={s.key}
            className={`tab ${sort === s.key ? "active" : ""}`}
            onClick={() => changeSort(s.key)}
          >
            {s.label}
          </button>
        ))}
      </div>

      <div style={{ overflowX: "auto" }}>
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Player</th>
              <th>High</th>
              <th>Total</th>
              <th>Level</th>
              <th>★</th>
              <th>Wins</th>
              <th>Combo</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((e) => (
              <tr key={e.playerId}>
                <td className="rank">{e.rank}</td>
                <td>
                  <div className="player">
                    <span className="avatar">{e.avatarEmoji}</span>
                    <span>{e.displayName}</span>
                  </div>
                </td>
                <td>{e.highScore.toLocaleString()}</td>
                <td>{e.totalScore.toLocaleString()}</td>
                <td>{e.highestLevel}</td>
                <td>{e.totalStars}</td>
                <td>
                  {e.wins}
                  <span className="muted"> ({e.winRate}%)</span>
                </td>
                <td>{e.maxCombo}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
