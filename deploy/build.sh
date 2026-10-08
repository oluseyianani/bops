#!/usr/bin/env bash
# Production build for the server on trolley: Next's standalone output (what the Mac app ships too),
# plus the two folders the standalone server expects next to itself. Run from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=2560}"
npm run build
rm -rf .next/standalone/.next/static .next/standalone/public
cp -r .next/static .next/standalone/.next/static
cp -r public .next/standalone/public
echo "built: node deploy/start.cjs"
