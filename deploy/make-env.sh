#!/usr/bin/env bash
# Writes .env.local for this fork's self-hosted server from the key files in ~/.config/bops
# (bop_openai.env, computer_openai.env, orgo.env), so the values never pass through a chat or a commit.
# Usage: deploy/make-env.sh [public-host]   (default bops.oluseyi.dev; use localhost for a Mac test)
set -euo pipefail
cd "$(dirname "$0")/.."
HOST="${1:-bops.oluseyi.dev}"
CFG="$HOME/.config/bops"
for f in bop_openai.env computer_openai.env orgo.env; do [ -f "$CFG/$f" ] || { echo "missing $CFG/$f" >&2; exit 1; }; done
# shellcheck disable=SC1091
set -a; . "$CFG/bop_openai.env"; . "$CFG/computer_openai.env"; . "$CFG/orgo.env"; set +a
umask 077
cat > .env.local <<ENV
# Made by deploy/make-env.sh on $(date -u +%Y-%m-%dT%H:%MZ). Never commit.
BOPS_SELF_HOSTED=1
OPENAI_API_KEY=${BOPS_OPENAI_API:?}
OPENAI_EXECUTOR_API_KEY=${COMPUTER_OPENAI_API_RESTRICTED:?}
ORGO_API_KEY=${ORGO_API:?}
BOPS_PUBLIC_HOST=${HOST}
BOPS_PUBLIC_URL=https://${HOST}
BOPS_CHAT_EFFORT=high
# Hard tasks on the same model as the rest (gpt-6-astra costs five times as much).
BOPS_HARD_MODEL=gpt-6.1-sol
# Optional services, filled in later (see FORK.md): HONCHO_API_KEY, TYPESAFE_API_KEY, COMPOSIO_API_KEY,
# TAILSCALE_AUTH_KEY, AGENTMAIL_API_KEY, SENDBLUE_*.
ENV
echo "wrote .env.local for ${HOST}"
