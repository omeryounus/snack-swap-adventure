import { error, json, options } from "@/lib/http";
import { getLeaderboard } from "@/lib/store";
import type { LeaderboardSort } from "@/lib/types";

const SORTS: LeaderboardSort[] = [
  "highScore",
  "totalScore",
  "highestLevel",
  "totalStars",
  "wins",
  "maxCombo",
];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const sortParam = (searchParams.get("sort") || "highScore") as LeaderboardSort;
  const limit = Number(searchParams.get("limit") || "50");

  if (!SORTS.includes(sortParam)) {
    return error(`Invalid sort. Use one of: ${SORTS.join(", ")}`);
  }

  const entries = getLeaderboard(sortParam, Number.isFinite(limit) ? limit : 50);
  return json({
    sort: sortParam,
    count: entries.length,
    entries,
  });
}

export async function OPTIONS() {
  return options();
}
