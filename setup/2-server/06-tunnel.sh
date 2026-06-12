#!/usr/bin/env bash
# Cloudflare Tunnel als compose-Service (profile "tunnel") starten.
# Voraussetzung: CF_TUNNEL_TOKEN gesetzt (in .env oder Env). Idempotent.
# Aufruf:  APP_USER=ops bash setup/2-server/06-tunnel.sh
set -euo pipefail

APP_USER="${APP_USER:-ops}"
APP_DIR="${APP_DIR:-/home/$APP_USER/app}"
ENV_FILE="$APP_DIR/setup/3-bot/.env"

if [ -z "${CF_TUNNEL_TOKEN:-}" ] && [ -f "$ENV_FILE" ]; then
    # Wert aus .env ziehen, ohne sie zu sourcen.
    CF_TUNNEL_TOKEN="$(grep -E '^CF_TUNNEL_TOKEN=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"
fi

if [ -z "${CF_TUNNEL_TOKEN:-}" ]; then
    echo '[!] CF_TUNNEL_TOKEN fehlt (Env oder .env). Tunnel uebersprungen.'
    exit 1
fi

if ! [ -d "$APP_DIR/setup/3-bot" ]; then
    echo "[!] $APP_DIR/setup/3-bot nicht da. Erst 05-deploy.sh."
    exit 1
fi

sudo -u "$APP_USER" bash -euo pipefail <<EOF
cd "$APP_DIR/setup/3-bot"
docker compose --profile tunnel up -d tunnel
docker compose --profile tunnel ps tunnel
EOF

echo
echo '[ok] tunnel laeuft.'
echo
echo 'Hinweis: im Cloudflare Dashboard (Zero Trust -> Networks -> Tunnels)'
echo '   Public Hostname anlegen:  bot.deine-domain  ->  http://bot:8080'
