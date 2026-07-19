import { json, options } from "@/lib/http";

export async function GET() {
  return json({
    ok: true,
    service: "snack-swap-adventure-api",
    version: "1.0.0",
    time: new Date().toISOString(),
  });
}

export async function OPTIONS() {
  return options();
}
