#!/usr/bin/env bash
# Docker Engine + Compose plugin. Als root. Idempotent.
set -euo pipefail

APP_USER="${APP_USER:-ops}"

if ! command -v docker >/dev/null 2>&1; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
        >/etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io \
                       docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker
id "$APP_USER" >/dev/null 2>&1 && usermod -aG docker "$APP_USER" || true

docker --version
docker compose version
echo '[ok] docker fertig.'
