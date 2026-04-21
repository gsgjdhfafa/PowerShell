#!/usr/bin/env bash
# ============================================================
# VPS - SSH Hardening + UFW Firewall + fail2ban
# Ausfuehren: als root
# Idempotent.
# Wichtig: Erst sicherstellen, dass 'ops' per SSH-Key
# einloggen kann, sonst sperrst du dich aus.
# ============================================================
set -euo pipefail

# --- 1. SSH haerten -------------------------------------------
SSHD=/etc/ssh/sshd_config.d/99-hardening.conf
cat >"$SSHD" <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 20
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
chmod 644 "$SSHD"
sshd -t
systemctl reload ssh || systemctl reload sshd

# --- 2. UFW Firewall ------------------------------------------
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'
ufw allow 80/tcp comment 'http'
ufw allow 443/tcp comment 'https'
ufw --force enable
ufw status verbose

# --- 3. fail2ban (SSH-Jail) ----------------------------------
cat >/etc/fail2ban/jail.d/ssh.local <<'EOF'
[sshd]
enabled  = true
port     = 22
maxretry = 5
bantime  = 1h
findtime = 10m
EOF

systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[ok] hardening fertig."
