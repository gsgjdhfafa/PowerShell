#!/usr/bin/env bash
# One-Shot Server Bootstrap. Verkettet 01..04 (+ optional 05). Idempotent.
# Aufruf (als root):
#   APP_USER=ops bash setup/2-server/bootstrap.sh
# Mit Deploy:
#   APP_USER=ops REPO_URL=git@github.com:<u>/<r>.git BRANCH=main \
#       bash setup/2-server/bootstrap.sh
set -euo pipefail

# Skript-Verzeichnis (auch wenn ueber Pipe/Pfad aufgerufen).
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APP_USER="${APP_USER:-ops}"
export SSH_PORT="${SSH_PORT:-22}"

[ "$(id -u)" -eq 0 ] || { echo '[!] Bitte als root ausfuehren.'; exit 1; }

echo "[*] 01 base"
bash "$SD/01-base.sh"

echo "[*] 02 security (kann abbrechen, wenn $APP_USER keinen Pubkey hat)"
bash "$SD/02-security.sh"

echo "[*] 03 docker"
bash "$SD/03-docker.sh"

echo "[*] 04 node"
bash "$SD/04-node.sh"

if [ -n "${REPO_URL:-}" ]; then
    echo "[*] 05 deploy"
    bash "$SD/05-deploy.sh"
else
    echo "[i] REPO_URL nicht gesetzt -> Deploy uebersprungen."
fi

# Tunnel nur wenn Token gesetzt ist (Env oder bereits in .env nach Deploy).
ENV_FILE="/home/${APP_USER}/app/setup/3-bot/.env"
TUNNEL_TOKEN="${CF_TUNNEL_TOKEN:-}"
if [ -z "$TUNNEL_TOKEN" ] && [ -f "$ENV_FILE" ]; then
    TUNNEL_TOKEN="$(grep -E '^CF_TUNNEL_TOKEN=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"
fi
if [ -n "$TUNNEL_TOKEN" ]; then
    echo "[*] 06 tunnel"
    CF_TUNNEL_TOKEN="$TUNNEL_TOKEN" bash "$SD/06-tunnel.sh"
else
    echo "[i] CF_TUNNEL_TOKEN nicht gesetzt -> Tunnel uebersprungen (Bot laeuft trotzdem)."
fi

echo "[done] bootstrap fertig."
