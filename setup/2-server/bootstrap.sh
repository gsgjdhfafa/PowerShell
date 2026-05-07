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

echo "[done] bootstrap fertig."
