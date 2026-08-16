import { json, error, options } from "../../../../lib/http.js";
import { redeemInviteCode, ensureHydrated } from "../../../../lib/store.js";

/**
 * POST /api/friends/redeem { playerId, code }
 * Links both players. `rewarded` is true only for a genuinely new link, so a
 * replayed request cannot be farmed for stars.
 */
export async function POST(request) {
  await ensureHydrated();
  let body;
  try {
    body = await request.json();
  } catch {
    return error("Invalid JSON body");
  }
  const playerId = body?.playerId;
  const code = body?.code;
  if (!playerId) return error("playerId is required");
  if (!code) return error("code is required");

  const result = redeemInviteCode({ playerId, code });
  if (result.error) return error(result.error, 400);
  return json(result);
}

export async function OPTIONS() { return options(); }
