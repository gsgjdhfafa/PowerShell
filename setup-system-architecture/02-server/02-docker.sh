#!/usr/bin/env bash
# ============================================================
# VPS - Docker + Node.js + Git
# Ausfuehren: als root
# Idempotent.
# ============================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# --- 1. Docker ------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $CODENAME stable" \
        >/etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker
usermod -aG docker ops || true

# --- 2. Node.js 20 LTS ---------------------------------------
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d. -f1)" != "v20" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

# --- 3. Git (sicherstellen) ----------------------------------
command -v git >/dev/null 2>&1 || apt-get install -y git

# --- 4. Versionen ausgeben -----------------------------------
echo "[ok] docker: $(docker --version)"
echo "[ok] node:   $(node --version)"
echo "[ok] npm:    $(npm --version)"
echo "[ok] git:    $(git --version)"
