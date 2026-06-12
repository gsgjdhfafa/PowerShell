#!/usr/bin/env bash
# Bot ausrollen: klont/aktualisiert Repo, startet via docker compose.
# Als Benutzer $APP_USER (oder root mit sudo -u). Idempotent.
set -euo pipefail

APP_USER="${APP_USER:-ops}"
APP_DIR="${APP_DIR:-/home/$APP_USER/app}"
REPO_URL="${REPO_URL:?REPO_URL fehlt (z.B. git@github.com:user/repo.git)}"
BRANCH="${BRANCH:-main}"

sudo -u "$APP_USER" bash -euo pipefail <<EOF
mkdir -p "$APP_DIR"
cd "$APP_DIR"
if [ -d .git ]; then
    git fetch --all --prune
    git checkout "$BRANCH"
    git reset --hard "origin/$BRANCH"
else
    git clone -b "$BRANCH" "$REPO_URL" .
fi

cd setup/3-bot
[ -f .env ] || { echo '[!] .env fehlt. Aus .env.example kopieren und ausfuellen.'; exit 1; }

docker compose pull || true
docker compose up -d --build
docker compose ps
EOF

echo '[ok] deploy fertig.'
