import { json, error, options } from "../../../lib/http.js";
import { createChallenge, listChallenges, ensureHydrated } from "../../../lib/store.js";

/** GET /api/challenges?playerId=… — inbox and sent list. */
export async function GET(request) {
  await ensureHydrated();
  const { searchParams } = new URL(request.url);
  const playerId = searchParams.get("playerId");
  if (!playerId) return error("playerId is required");
  const { incoming, outgoing } = listChallenges(playerId);
  return json({ playerId, incoming, outgoing });
}

/** POST /api/challenges { fromPlayerId, toPlayerId, level, targetScore } */
export async function POST(request) {
  await ensureHydrated();
  let body;
  try {
    body = await request.json();
  } catch {
    return error("Invalid JSON body");
  }
  const { fromPlayerId, toPlayerId, level, targetScore } = body || {};
  if (!fromPlayerId || !toPlayerId) return error("fromPlayerId and toPlayerId are required");
  if (!Number.isFinite(Number(level))) return error("level is required");

  const result = createChallenge({
    fromPlayerId,
    toPlayerId,
    level: Number(level),
    targetScore: Number(targetScore || 0),
  });
  if (result.error) return error(result.error, 400);
  return json(result, 201);
}

export async function OPTIONS() { return options(); }
