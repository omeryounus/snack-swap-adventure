
function json(data, status = 200) {
  return Response.json(data, {
    status,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Player-Id",
      "Cache-Control": "no-store",
    },
  });
}
function error(message, status = 400) { return json({ error: message }, status); }
function options() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Player-Id",
      "Access-Control-Max-Age": "86400",
    },
  });
}
export { json, error, options };
