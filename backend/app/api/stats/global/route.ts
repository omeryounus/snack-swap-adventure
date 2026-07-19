import { json, options } from "@/lib/http";
import { getGlobalStats, getLeaderboard, recentScores } from "@/lib/store";

export async function GET() {
  return json({
    global: getGlobalStats(),
    top3: getLeaderboard("highScore", 3),
    recent: recentScores(10),
  });
}

export async function OPTIONS() {
  return options();
}
