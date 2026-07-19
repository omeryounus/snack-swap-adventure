import { json, error, options } from "../../../lib/http.js";
import { listPlayers, upsertPlayer, winRate , ensureHydrated } from "../../../lib/store.js";
export async function GET() {

  await ensureHydrated();  const players = listPlayers().map(p => ({
    ...p, winRate: winRate(p.stats),
    averageScore: p.stats.gamesPlayed > 0 ? Math.round(p.stats.totalScore / p.stats.gamesPlayed) : 0
  })).sort((a,b) => b.stats.highScore - a.stats.highScore);
  return json({ count: players.length, players });
}
export async function POST(request) {

  await ensureHydrated();  try {
    const body = await request.json();
    const displayName = String(body.displayName || "").trim();
    if (!displayName) return error("displayName is required");
    const player = upsertPlayer({ id: body.playerId ? String(body.playerId) : undefined, displayName, avatarEmoji: body.avatarEmoji ? String(body.avatarEmoji) : undefined });
    return json({ player: { ...player, winRate: winRate(player.stats) } }, 201);
  } catch { return error("Invalid JSON body"); }
}
export async function OPTIONS() { return options(); }
