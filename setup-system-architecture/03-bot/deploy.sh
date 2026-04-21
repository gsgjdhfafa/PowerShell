#!/usr/bin/env bash
# ============================================================
# Bot Deploy - auf VPS ausfuehren (im Repo-Root)
# Voraussetzung: docker + compose installiert (02-server/02-docker.sh)
# Voraussetzung: 03-bot/.env gefuellt (siehe .env.example)
# Idempotent.
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/03-bot"

if [ ! -f .env ]; then
    echo "[err] 03-bot/.env fehlt. Von .env.example kopieren und ausfuellen."
    exit 1
fi

# minimale Pflicht-Variablen pruefen
required=(TELEGRAM_BOT_TOKEN TELEGRAM_ALLOWED_USER_ID NOTION_TOKEN \
          NOTION_DB_MEMORY NOTION_DB_TASKS NOTION_DB_COSTS)
missing=0
for k in "${required[@]}"; do
    if ! grep -q "^${k}=.\+" .env; then
        echo "[err] .env: $k fehlt oder leer"
        missing=1
    fi
done
if [ "$missing" -eq 1 ]; then exit 1; fi

docker compose pull  || true
docker compose build
docker compose up -d --force-recreate

echo "[ok] bot laeuft. logs: docker compose logs -f"
