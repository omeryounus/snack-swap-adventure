#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Deploy with the logged-in Vercel CLI account (run `npx vercel login` once).
# Optional: VERCEL_TOKEN=... for non-interactive CI deploys.

ARGS=(--prod --yes --scope omeryounus-projects)
if [ -n "${VERCEL_TOKEN:-}" ]; then
  ARGS+=(--token "$VERCEL_TOKEN")
fi

npx --yes vercel@latest "${ARGS[@]}"
