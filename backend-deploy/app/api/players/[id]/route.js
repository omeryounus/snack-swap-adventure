import { json, error, options } from "../../../../lib/http.js";
import { getPlayer, updatePlayerProfile, getLeaderboard, winRate , ensureHydrated } from "../../../../lib/store.js";
export async function GET(_req, { params }) {

  await ensureHydrated();  const { id } = await params;
  const player = getPlayer(id);
  if (!player) return error("Player not found", 404);
  const board = getLeaderboard("highScore", 200);
  const rank = (board.find(e => e.playerId === id) || {}).rank || null;
  return json({ player: { ...player, winRate: winRate(player.stats), averageScore: player.stats.gamesPlayed > 0 ? Math.round(player.stats.totalScore / player.stats.gamesPlayed) : 0, rank } });
}
export async function PATCH(request, { params }) {

  await ensureHydrated();  const { id } = await params;
  try {
    const body = await request.json();
    const player = updatePlayerProfile(id, { displayName: body.displayName ? String(body.displayName) : undefined, avatarEmoji: body.avatarEmoji ? String(body.avatarEmoji) : undefined });
    if (!player) return error("Player not found", 404);
    return json({ player: { ...player, winRate: winRate(player.stats) } });
  } catch { return error("Invalid JSON body"); }
}
export async function OPTIONS() { return options(); }
