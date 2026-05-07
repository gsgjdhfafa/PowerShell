#!/usr/bin/env bash
# Bot-Update: Repo aktualisieren + Container neu bauen. Idempotent.
# Aufruf:
#   APP_USER=ops BRANCH=main bash setup/2-server/update.sh
set -euo pipefail

APP_USER="${APP_USER:-ops}"
APP_DIR="${APP_DIR:-/home/$APP_USER/app}"
BRANCH="${BRANCH:-main}"

[ -d "$APP_DIR/.git" ] || { echo "[!] $APP_DIR ist kein Git-Repo. Erst 05-deploy.sh."; exit 1; }

sudo -u "$APP_USER" bash -euo pipefail <<EOF
cd "$APP_DIR"
git fetch --all --prune
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

cd setup/3-bot
[ -f .env ] || { echo '[!] .env fehlt.'; exit 1; }

docker compose pull || true
docker compose up -d --build
docker compose ps
EOF

echo '[ok] update fertig.'
