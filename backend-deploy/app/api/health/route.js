import { json, options } from "../../../lib/http.js";
import { durabilityInfo, ensureHydrated } from "../../../lib/store.js";

export async function GET() {
  await ensureHydrated();
  return json({
    ok: true,
    service: "snack-swap-adventure-api",
    version: "2.0.0",
    time: new Date().toISOString(),
    durability: durabilityInfo(),
  });
}

export async function OPTIONS() {
  return options();
}
