import { json, error, options } from "../../../lib/http.js";
import { getLeaderboard , ensureHydrated } from "../../../lib/store.js";
const SORTS = ["highScore","totalScore","highestLevel","totalStars","wins","maxCombo"];
export async function GET(request) {

  await ensureHydrated();  const { searchParams } = new URL(request.url);
  const sort = searchParams.get("sort") || "highScore";
  const limit = Number(searchParams.get("limit") || "50");
  if (!SORTS.includes(sort)) return error("Invalid sort. Use: " + SORTS.join(", "));
  const entries = getLeaderboard(sort, Number.isFinite(limit) ? limit : 50);
  return json({ sort, count: entries.length, entries });
}
export async function OPTIONS() { return options(); }
