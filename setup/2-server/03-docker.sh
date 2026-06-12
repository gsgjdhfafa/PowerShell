#!/usr/bin/env bash
# Docker Engine + Compose plugin. Als root. Idempotent.
set -euo pipefail

APP_USER="${APP_USER:-ops}"

have_docker()  { command -v docker >/dev/null 2>&1; }
have_compose() { docker compose version >/dev/null 2>&1; }

# Repo + Pakete nur einrichten, wenn etwas fehlt. Wenn Docker schon da ist,
# aber Compose-Plugin nicht, installieren wir nur das Plugin nach.
if ! have_docker || ! have_compose; then
    install -m 0755 -d /etc/apt/keyrings
    if [ ! -s /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    . /etc/os-release
    repo_line="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable"
    if [ ! -f /etc/apt/sources.list.d/docker.list ] \
       || ! grep -qF "$repo_line" /etc/apt/sources.list.d/docker.list; then
        echo "$repo_line" >/etc/apt/sources.list.d/docker.list
    fi

    apt-get update -y
    if ! have_docker; then
        apt-get install -y docker-ce docker-ce-cli containerd.io \
                           docker-buildx-plugin docker-compose-plugin
    else
        # Docker ist da, nur Compose-Plugin (und ggf. Buildx) nachziehen.
        apt-get install -y docker-compose-plugin docker-buildx-plugin
    fi
fi

systemctl enable --now docker
id "$APP_USER" >/dev/null 2>&1 && usermod -aG docker "$APP_USER" || true

docker --version
docker compose version
echo '[ok] docker fertig.'
