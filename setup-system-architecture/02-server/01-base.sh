#!/usr/bin/env bash
# ============================================================
# VPS BASE - Ubuntu 22.04/24.04
# Ausfuehren: als root
#   curl -fsSL <url>/01-base.sh | bash
# Idempotent.
# ============================================================
set -euo pipefail

# --- 1. System aktuell halten ---------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl wget git ca-certificates gnupg lsb-release \
    ufw fail2ban unattended-upgrades jq \
    software-properties-common

# --- 2. Zeitzone + NTP ----------------------------------------
timedatectl set-timezone Europe/Berlin
systemctl enable --now systemd-timesyncd

# --- 3. Non-root User 'ops' mit sudo --------------------------
if ! id -u ops >/dev/null 2>&1; then
    useradd -m -s /bin/bash ops
    usermod -aG sudo ops
    mkdir -p /home/ops/.ssh
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/ops/.ssh/authorized_keys
    fi
    chown -R ops:ops /home/ops/.ssh
    chmod 700 /home/ops/.ssh
    [ -f /home/ops/.ssh/authorized_keys ] && chmod 600 /home/ops/.ssh/authorized_keys
fi

# --- 4. Unattended upgrades aktivieren ------------------------
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

echo "[ok] base fertig."
