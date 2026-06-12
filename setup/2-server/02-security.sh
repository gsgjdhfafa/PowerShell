#!/usr/bin/env bash
# SSH haerten + Firewall. Als root ausfuehren. Idempotent.
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
APP_USER="${APP_USER:-ops}"
# Lockout-Schutz umgehen nur wenn explizit gewollt:
ALLOW_PASSWORD_AUTH="${ALLOW_PASSWORD_AUTH:-0}"

# --- 0. Precheck: Key-Login muss fuer mind. einen Nicht-Root-User gehen ------
# Sonst sperren wir uns aus, sobald die aktuelle Session endet.
key_user_has_keys() {
    local u="$1" home keyfile
    home=$(getent passwd "$u" | cut -d: -f6) || return 1
    [ -n "$home" ] || return 1
    keyfile="$home/.ssh/authorized_keys"
    [ -s "$keyfile" ] && grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-)' "$keyfile"
}

if ! id "$APP_USER" >/dev/null 2>&1; then
    echo "[!] User '$APP_USER' fehlt. Erst 01-base.sh laufen lassen."
    exit 1
fi

if ! key_user_has_keys "$APP_USER"; then
    cat >&2 <<EOF
[!] STOP: User '$APP_USER' hat keine SSH-Pubkeys in ~/.ssh/authorized_keys.
    Wuerde dieses Skript jetzt PasswordAuthentication abschalten, kaemst du
    nach Sessionende nicht mehr rein.

    Loesung: lokal (NICHT auf dem Server) ausfuehren, Pfad anpassen:
      ssh-copy-id -i ~/.ssh/id_ed25519.pub ${APP_USER}@<server-ip>
    Anschliessend testen:
      ssh ${APP_USER}@<server-ip>   # muss ohne Passwort durchgehen
    Dann dieses Skript erneut starten.

    Override (auf eigene Gefahr; laesst PasswordAuthentication an):
      ALLOW_PASSWORD_AUTH=1 bash 02-security.sh
EOF
    [ "$ALLOW_PASSWORD_AUTH" = "1" ] || exit 1
    echo "[!] ALLOW_PASSWORD_AUTH=1 -> PasswordAuthentication bleibt 'yes'."
fi

# --- SSH Config ---------------------------------------------------------------
sshd_cfg=/etc/ssh/sshd_config
cp -n "$sshd_cfg" "$sshd_cfg.bak"

set_cfg() {
    local key="$1" val="$2"
    if grep -qE "^[#[:space:]]*${key}[[:space:]]" "$sshd_cfg"; then
        sed -ri "s|^[#[:space:]]*(${key})[[:space:]].*|\1 ${val}|" "$sshd_cfg"
    else
        echo "${key} ${val}" >>"$sshd_cfg"
    fi
}

# Pubkey muss generell an sein (Default in Ubuntu, doppelt ist sicher):
set_cfg PubkeyAuthentication       yes
set_cfg PermitRootLogin            no
if [ "$ALLOW_PASSWORD_AUTH" = "1" ]; then
    set_cfg PasswordAuthentication yes
else
    set_cfg PasswordAuthentication no
fi
set_cfg KbdInteractiveAuthentication no
set_cfg ChallengeResponseAuthentication no
set_cfg X11Forwarding              no
set_cfg Port                       "$SSH_PORT"

sshd -t
systemctl reload ssh || systemctl reload sshd

# --- UFW ----------------------------------------------------------------------
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp" comment 'ssh'
ufw allow 80/tcp             comment 'http'
ufw allow 443/tcp            comment 'https'
ufw --force enable

# --- fail2ban -----------------------------------------------------------------
cat >/etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled  = true
port     = ${SSH_PORT}
backend  = systemd
maxretry = 5
bantime  = 1h
findtime = 10m
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

# --- unattended upgrades ------------------------------------------------------
dpkg-reconfigure -f noninteractive unattended-upgrades || true

echo "[ok] security fertig. ssh port=$SSH_PORT, ufw=on, fail2ban=on"
