#!/usr/bin/env bash
# Node.js LTS + Git. Als root. Idempotent.
set -euo pipefail

if ! command -v node >/dev/null 2>&1 || ! node -v | grep -qE '^v(20|22)\.'; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

apt-get install -y git

node -v
npm -v
git --version
echo '[ok] node + git fertig.'
