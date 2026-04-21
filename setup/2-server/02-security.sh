#!/usr/bin/env bash
# SSH haerten + Firewall. Als root ausfuehren. Idempotent.
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"

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

set_cfg PermitRootLogin            no
set_cfg PasswordAuthentication     no
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
