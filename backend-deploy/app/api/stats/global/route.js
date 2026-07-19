import { json, options } from "../../../../lib/http.js";
import { getGlobalStats, getLeaderboard, recentScores , ensureHydrated } from "../../../../lib/store.js";
export async function GET() {

  await ensureHydrated();  return json({ global: getGlobalStats(), top3: getLeaderboard("highScore", 3), recent: recentScores(10) });
}
export async function OPTIONS() { return options(); }
