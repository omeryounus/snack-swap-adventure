import { json, error, options } from "../../../../lib/http.js";
import { respondToChallenge, ensureHydrated } from "../../../../lib/store.js";

/** POST /api/challenges/respond { challengeId, playerId, score } */
export async function POST(request) {
  await ensureHydrated();
  let body;
  try {
    body = await request.json();
  } catch {
    return error("Invalid JSON body");
  }
  const { challengeId, playerId, score } = body || {};
  if (!challengeId) return error("challengeId is required");
  if (!playerId) return error("playerId is required");

  const result = respondToChallenge({
    challengeId,
    playerId,
    score: Number(score || 0),
  });
  if (result.error) return error(result.error, 400);
  return json(result);
}

export async function OPTIONS() { return options(); }
