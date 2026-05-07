#!/usr/bin/env bash
# Server Health-Check. Read-only. Idempotent.
# Aufruf:  bash setup/2-server/doctor.sh
set -uo pipefail

APP_USER="${APP_USER:-ops}"
APP_DIR="${APP_DIR:-/home/$APP_USER/app}"
RC=0

ok()   { printf "  [ok]   %s\n" "$*"; }
warn() { printf "  [WARN] %s\n" "$*"; RC=1; }
fail() { printf "  [FAIL] %s\n" "$*"; RC=2; }

section() { printf "\n== %s ==\n" "$*"; }

section 'system'
command -v docker  >/dev/null 2>&1 && ok "docker $(docker --version | awk '{print $3}' | tr -d ,)" || fail 'docker fehlt'
docker compose version >/dev/null 2>&1 && ok "docker compose $(docker compose version --short)" || fail 'compose plugin fehlt'
command -v node    >/dev/null 2>&1 && ok "node $(node -v)" || warn 'node fehlt'
command -v git     >/dev/null 2>&1 && ok "git $(git --version | awk '{print $3}')" || warn 'git fehlt'

section 'security'
systemctl is-active --quiet ufw      && ok 'ufw aktiv'      || warn 'ufw inaktiv'
systemctl is-active --quiet fail2ban && ok 'fail2ban aktiv' || warn 'fail2ban inaktiv'
ssh_root=$(sshd -T 2>/dev/null | awk '/^permitrootlogin/{print $2}')
[ "$ssh_root" = 'no' ] && ok 'ssh root login: no' || warn "ssh root login: ${ssh_root:-?}"
ssh_pw=$(sshd -T 2>/dev/null | awk '/^passwordauthentication/{print $2}')
[ "$ssh_pw" = 'no' ] && ok 'ssh password auth: no' || warn "ssh password auth: ${ssh_pw:-?}"

section 'app'
if [ -d "$APP_DIR/.git" ]; then
    ok "repo: $APP_DIR ($(git -C "$APP_DIR" rev-parse --short HEAD) on $(git -C "$APP_DIR" rev-parse --abbrev-ref HEAD))"
else
    warn "kein git-repo unter $APP_DIR"
fi

env_file="$APP_DIR/setup/3-bot/.env"
if [ -f "$env_file" ]; then
    ok ".env vorhanden"
    for k in TELEGRAM_BOT_TOKEN NOTION_TOKEN NOTION_DB_MEMORY NOTION_DB_TASKS NOTION_DB_COSTS; do
        grep -qE "^${k}=.+" "$env_file" && ok "  $k gesetzt" || warn "  $k leer/fehlt"
    done
    grep -qE '^(OPENAI_API_KEY|ANTHROPIC_API_KEY)=.+' "$env_file" \
        && ok '  AI-Key gesetzt' || warn '  weder OPENAI_API_KEY noch ANTHROPIC_API_KEY gesetzt'
else
    warn ".env fehlt: $env_file"
fi

section 'container'
if docker ps --format '{{.Names}}' | grep -qx 'zf-bot'; then
    ok 'zf-bot laeuft'
    rs=$(docker inspect -f '{{.RestartCount}}' zf-bot 2>/dev/null || echo '?')
    health=$(docker inspect -f '{{.State.Status}}' zf-bot 2>/dev/null || echo '?')
    ok "  status=$health restarts=$rs"
    echo '  letzte logs:'
    docker logs --tail=5 zf-bot 2>&1 | sed 's/^/    /'
else
    fail 'zf-bot Container nicht gefunden'
fi

section 'resources'
df -h / | awk 'NR==2{printf "  disk /: %s used of %s (%s)\n", $3, $2, $5}'
free -h | awk '/Mem:/{printf "  mem   : %s used of %s\n", $3, $2}'
uptime  | awk -F'load average:' '{printf "  load  :%s\n", $2}'

echo
case $RC in
    0) echo '[done] alles gruen.' ;;
    1) echo '[done] mit warnungen.' ;;
    *) echo '[done] kritische probleme.' ;;
esac
exit $RC
