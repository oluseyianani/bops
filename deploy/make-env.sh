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
ENV
# Optional services: one file each in ~/.config/bops, <name>.env holding <VAR>=<value>, added when present.
optional() { # file var-in var-out
  [ -f "$CFG/$1" ] || return 0
  local v; v=$(grep -m1 "^$2=" "$CFG/$1" | cut -d= -f2- || true)
  [ -n "$v" ] || return 0
  echo "$3=$v" >> .env.local && echo "  + $3 (from $1)"
}
optional honcho.env     HONCHO_API         HONCHO_API_KEY
optional typesafe.env   TYPESAFE_API       TYPESAFE_API_KEY
optional composio.env   COMPOSIO_API       COMPOSIO_API_KEY
optional tailscale.env  TAILSCALE_AUTH     TAILSCALE_AUTH_KEY
optional agentmail.env  AGENTMAIL_API      AGENTMAIL_API_KEY
optional agentphone.env AGENTPHONE_API     AGENTPHONE_API_KEY
# With AgentPhone, texts and call turns are delivered to this server (Caddy lets that path through without auth).
[ -f "$CFG/agentphone.env" ] && echo "BOPS_AGENTPHONE_HOOK_URL=https://${HOST}/api/phone/agentphone" >> .env.local
optional agentphone.env AGENTPHONE_SUB     AGENTPHONE_SUB_ACCOUNT
optional agentphone.env AGENTPHONE_SECRET  AGENTPHONE_WEBHOOK_SECRET
optional phone.env      OWNER_PHONES       BOPS_OWNER_PHONES
optional phone.env      PHONE_AREA         BOPS_PHONE_AREA
echo "wrote .env.local for ${HOST}"
