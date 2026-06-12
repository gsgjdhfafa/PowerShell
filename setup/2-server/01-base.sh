#!/usr/bin/env bash
# VPS Base: Updates, Zeit, User. Idempotent. Als root ausfuehren.
set -euo pipefail

APP_USER="${APP_USER:-ops}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl git ufw fail2ban unattended-upgrades \
                   software-properties-common gnupg lsb-release tzdata jq

timedatectl set-timezone Europe/Berlin || true

# User anlegen (idempotent)
if ! id "$APP_USER" >/dev/null 2>&1; then
    adduser --disabled-password --gecos '' "$APP_USER"
    usermod -aG sudo "$APP_USER"
fi

# SSH Key vom root uebernehmen, falls vorhanden und User-Key fehlt.
install -d -m 700 -o "$APP_USER" -g "$APP_USER" "/home/$APP_USER/.ssh"
if [ -f /root/.ssh/authorized_keys ] && [ ! -s "/home/$APP_USER/.ssh/authorized_keys" ]; then
    cp /root/.ssh/authorized_keys "/home/$APP_USER/.ssh/authorized_keys"
    chown "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh/authorized_keys"
    chmod 600 "/home/$APP_USER/.ssh/authorized_keys"
fi

# passwortloses sudo fuer Automatisierung
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-$APP_USER
chmod 440 /etc/sudoers.d/90-$APP_USER

echo "[ok] base fertig. User: $APP_USER"
