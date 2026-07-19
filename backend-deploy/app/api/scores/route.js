import { json, error, options } from "../../../lib/http.js";
import { recentScores, submitScore, winRate , ensureHydrated } from "../../../lib/store.js";
export async function GET(request) {

  await ensureHydrated();  const limit = Number(new URL(request.url).searchParams.get("limit") || "20");
  const scores = recentScores(Number.isFinite(limit) ? limit : 20);
  return json({ count: scores.length, scores });
}
export async function POST(request) {

  await ensureHydrated();  try {
    const body = await request.json();
    const playerId = String(body.playerId || "").trim();
    if (!playerId) return error("playerId is required");
    if (typeof body.score !== "number" || typeof body.level !== "number") return error("level and score are required numbers");
    const result = submitScore({
      playerId, displayName: body.displayName ? String(body.displayName) : undefined,
      level: body.level, score: body.score,
      stars: typeof body.stars === "number" ? body.stars : 0,
      won: Boolean(body.won),
      movesLeft: typeof body.movesLeft === "number" ? body.movesLeft : 0,
      maxCombo: typeof body.maxCombo === "number" ? body.maxCombo : 0,
    });
    return json({ rank: result.rank, event: result.event, player: { ...result.player, winRate: winRate(result.player.stats) } }, 201);
  } catch { return error("Invalid JSON body"); }
}
export async function OPTIONS() { return options(); }
