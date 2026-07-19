import { json, error, options } from "../../../../lib/http.js";
import { getPlayer, getLeaderboard, winRate , ensureHydrated } from "../../../../lib/store.js";
export async function GET(_req, { params }) {

  await ensureHydrated();  const { playerId } = await params;
  const player = getPlayer(playerId);
  if (!player) return error("Player not found", 404);
  const board = getLeaderboard("highScore", 200);
  const entry = board.find(e => e.playerId === playerId);
  const avg = player.stats.gamesPlayed > 0 ? Math.round(player.stats.totalScore / player.stats.gamesPlayed) : 0;
  return json({
    playerId: player.id, displayName: player.displayName, avatarEmoji: player.avatarEmoji,
    rank: entry ? entry.rank : null,
    stats: { ...player.stats, winRate: winRate(player.stats), averageScore: avg },
    lastPlayedAt: player.lastPlayedAt, createdAt: player.createdAt
  });
}
export async function OPTIONS() { return options(); }
