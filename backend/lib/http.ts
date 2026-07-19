import { NextResponse } from "next/server";

export function json(data: unknown, status = 200) {
  return NextResponse.json(data, {
    status,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Player-Id",
      "Cache-Control": "no-store",
    },
  });
}

export function error(message: string, status = 400) {
  return json({ error: message }, status);
}

export function options() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Player-Id",
      "Access-Control-Max-Age": "86400",
    },
  });
}
