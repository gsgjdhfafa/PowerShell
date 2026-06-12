# End-to-End Flow

```
[PC]  Brave  ->  Notion Dashboard

[Telegram] /task ...  ─┐
                       │
[Gmail Filter "ZF"] ─> [CF Email Routing] ─> [CF Worker] ─┐
                                                          ▼
                                          [VPS bot (HTTP /mail or Telegram)]
                                                          │
                                                          ▼
                                                       [AI: classify + structure]
                                                          │
                                                          ▼
                                                  [Notion DB: Memory|Tasks|Costs]
                                                          │
                                       ┌──────────────────┼──────────────────┐
                                       ▼                  ▼                  ▼
                                 [Google Tasks]  [Google Calendar]  [Telegram-Reply]
```

## Reihenfolge nach frischer VPS

```bash
# als root auf dem Server (idempotent):
export APP_USER=ops
export REPO_URL=git@github.com:<u>/<r>.git
export BRANCH=main
# Optional: CF_TUNNEL_TOKEN setzt zusaetzlich Tunnel auf
# export CF_TUNNEL_TOKEN=eyJh...

bash setup/2-server/bootstrap.sh

# .env auf dem Server ausfuellen:
sudo -u ops vi /home/ops/app/setup/3-bot/.env

# Bot + Tunnel hochziehen / aktualisieren:
APP_USER=ops bash setup/2-server/update.sh
APP_USER=ops bash setup/2-server/06-tunnel.sh   # nur einmal noetig

# Verify
APP_USER=ops bash setup/2-server/doctor.sh
```

## Verify

```bash
# direkt
docker exec zf-bot wget -qO- http://127.0.0.1:8080/healthz

# durch Tunnel
curl -s https://bot.deine-domain/healthz

# Telegram
/start  -> Antwort mit Command-Liste
/status -> uptime, AI provider, Notion ok, google ok|off, webhook on|off
```

## Pre-flight Setup (einmalig)

1. Cloudflare: Domain dort gehostet, Email Routing aktiviert,
   Tunnel angelegt (Token kopieren).
2. Google Cloud Console: OAuth-Client "Desktop App", Consent-Screen "in production"
   (eigener Account), Token via `node setup/4-integration/oauth-helper.mjs`.
3. Notion: Integration "ZF" anlegen, 3 Datenbanken (Memory/Tasks/Costs)
   gemaess `notion-schema.md`, alle drei mit der Integration verbinden.
4. Telegram: `@BotFather` -> `/newbot` -> Token. `@userinfobot` -> User-ID.
5. Gmail: Filter "[ZF]" anlegen, Forward an `inbox@deine-domain`,
   siehe `gmail-filter.md`.
