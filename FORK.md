# This fork: Bops on trolley

> Fork-local documentation. Upstream's own docs are README.md and the folder READMEs; this file
> is deliberately separate so upstream merges never touch it.

## What this fork is

`oluseyianani/bops`, tracking `nickvasilescu/bops` (`upstream`), run as a single-user, self-hosted
server on trolley (Hetzner, Linux) instead of the Mac app, and reached in a browser at
https://bops.oluseyi.dev behind Caddy's basic auth. It runs alongside `boop-agent` (:3456,
trolley.oluseyi.dev), which stays: the two are different tools. Boop keeps the Sendblue number;
texting Boppy, if wanted, goes through a Telegram bot (built in, no public webhook needed).

Rules for fork-local work, so `git merge upstream/main` stays painless:

- New behaviour goes in new files (`lib/server/secrets-file.ts`, `deploy/`, this file). An existing
  upstream file gets at most a one-line hook per function, marked `Fork-local`.
- Never delete upstream code; turn it off with an env setting or a platform check instead.
- Nothing from `.env.local` or `~/.config/bops` is ever committed.

## What was added

| Piece | Where |
|---|---|
| Orgo plan read on `ORGO_API_KEY` when nobody is signed in (else the free Bops computer is never offered) | one line in `lib/server/plan.ts` `orgoPlan()` |
| Routes meant for "this Mac only" (phone, lines, call, vnc, mac) also take `BOPS_PUBLIC_HOST`, as proxy.ts does | `lib/server/our-hosts.ts`; one import + one token in each of those six routes |
| Secrets without a macOS Keychain: `.data/secrets.json` (0600), used when `process.platform` isn't darwin | `lib/server/secrets-file.ts`; three hooks in `lib/server/keychain.ts` |
| `.env.local` from the key files in `~/.config/bops` | `deploy/make-env.sh` |
| Build and start of the standalone server from the repo root | `deploy/build.sh`, `deploy/start.cjs` |
| systemd unit (port 3210, loopback, 2 GB cap) and the Caddy block | `deploy/bops-server.service`, `deploy/Caddyfile.snippet` |

## What the server needs

Hard requirements: an OpenAI API key (pay-per-use; nothing here can use a ChatGPT, Codex or Claude
subscription), an OpenAI *environment key* for the bots' computers (made on the dashboard's Agents
tab → Environments → Keys, in the same project; an ordinary secret key, even with "All"
permissions, lacks `api.agents.environments.connect`), and an Orgo API key (the free plan gives one free Bops computer). They live in
`~/.config/bops/{bop_openai,computer_openai,orgo}.env` as `BOPS_OPENAI_API`,
`COMPUTER_OPENAI_API_RESTRICTED` and `ORGO_API`; `deploy/make-env.sh` turns them into `.env.local`.

Optional, one file each in `~/.config/bops`, picked up by `make-env.sh` when present:
`honcho.env` (`HONCHO_API`, memory), `typesafe.env` (`TYPESAFE_API`, judgment calls),
`composio.env` (`COMPOSIO_API`, apps), `tailscale.env` (`TAILSCALE_AUTH`, live screen view),
`agentmail.env` (`AGENTMAIL_API`, bot inboxes), `agentphone.env` (`AGENTPHONE_API`,
`AGENTPHONE_SUB`, `AGENTPHONE_SECRET`; texts and calls) and `phone.env` (`OWNER_PHONES`: your own
mobile(s), E.164, which count as you without a texted code; `PHONE_AREA`).

Models default to `gpt-6.1-sol`; `make-env.sh` pins `BOPS_HARD_MODEL` to it too (astra costs 5x)
and sets `BOPS_CHAT_EFFORT=high`.

## Development (Mac)

```bash
ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm ci
deploy/make-env.sh localhost          # .env.local for a local run
npx next dev --port 3210              # open http://localhost:3210 in a browser
npx next typegen && npx tsc --noEmit -p . && npm run lint
```

## Deploying to trolley

trolley: Ubuntu x86_64, 2 vCPU, ~3.8 GB RAM plus a 2 GB swapfile, Node 24, Caddy, Tailscale.
Boop runs on :3456; Bops takes :3210.

1. **Deploy key** (per-repo, as for boop):
   ```bash
   ssh-keygen -t ed25519 -C "trolley bops deploy" -f ~/.ssh/id_ed25519_bops -N ""
   cat ~/.ssh/id_ed25519_bops.pub   # add: fork repo → Settings → Deploy keys (read-only)
   cat >> ~/.ssh/config <<'EOC'
   Host github-bops
     HostName github.com
     IdentityFile ~/.ssh/id_ed25519_bops
     IdentitiesOnly yes
   EOC
   git clone git@github-bops:oluseyianani/bops.git ~/apps/bops
   cd ~/apps/bops && ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm ci
   ```
2. **Keys:** copy `~/.config/bops/*.env` from the Mac (`scp`), then `deploy/make-env.sh`.
3. **Build:** `deploy/build.sh` (Next's standalone output, as the Mac app ships; the unit starts it with `deploy/start.cjs` from the repo root so `.data/` and `vm/` are where the server looks).
4. **Service:**
   ```bash
   sudo cp deploy/bops-server.service /etc/systemd/system/
   sudo systemctl daemon-reload && sudo systemctl enable --now bops-server
   curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3210/
   ```
5. **Caddy:** append `deploy/Caddyfile.snippet` to `/etc/caddy/Caddyfile` with the existing bcrypt
   hash, then `sudo caddy validate --config /etc/caddy/Caddyfile && sudo systemctl reload caddy`.
6. **Verify:** https://bops.oluseyi.dev → basic auth → Settings → You.

Never test-boot the server by hand on :3210 while the unit exists: Next's `next-server` child
outlives its parent, keeps the port, and the unit then loops on restart (kill the child by pid).

Redeploy after code changes:

```bash
cd ~/apps/bops && git pull && ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm ci && deploy/build.sh && sudo systemctl restart bops-server
```

## Syncing with upstream

```bash
git fetch upstream
git merge upstream/main     # conflicts only possible at the one-line hooks (keychain.ts, plan.ts, the six local-only routes)
npx next typegen && npx tsc --noEmit -p . && npm run lint
git push origin main
```

