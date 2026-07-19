#!/bin/bash
set -euo pipefail
TOKEN="${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
TEAM="team_6hPZUIQWamgigHD9sQzcMLSo"
NAME="snack-swap-adventure-api"
# Create deployment with files via API is complex (needs file uploads)

# Simpler: use vercel CLI
cd "$(dirname "$0")"
npx vercel@39 --prod --yes --token "$TOKEN" --scope omeryounus-projects
