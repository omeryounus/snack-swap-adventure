import { json, error, options } from "../../../lib/http.js";
import { listFriends, ensureHydrated } from "../../../lib/store.js";

/** GET /api/friends?playerId=… — everyone this player has swapped codes with. */
export async function GET(request) {
  await ensureHydrated();
  const { searchParams } = new URL(request.url);
  const playerId = searchParams.get("playerId");
  if (!playerId) return error("playerId is required");
  const friends = listFriends(playerId);
  return json({ playerId, count: friends.length, friends });
}

export async function OPTIONS() { return options(); }
