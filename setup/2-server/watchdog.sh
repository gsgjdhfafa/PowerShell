#!/usr/bin/env bash
# zf-bot Watchdog. Pingt /healthz, schickt Telegram-Alert wenn 3x in Folge fail.
# Aufruf via cron: */5 * * * * /home/ops/app/setup/2-server/watchdog.sh
# Idempotent. Lockfile verhindert Ueberlappung. Kein Body/Token loggen.
set -uo pipefail

APP_USER="${APP_USER:-ops}"
ENV_FILE="/home/${APP_USER}/app/setup/3-bot/.env"
STATE_DIR="/var/lib/zf-watchdog"
FAIL_FILE="$STATE_DIR/fail.count"
NOTIFIED_FLAG="$STATE_DIR/notified.flag"
LOCK_FILE="$STATE_DIR/lock"
THRESHOLD=3

log() { printf '%(%Y-%m-%dT%H:%M:%S%z)T %s\n' -1 "$*"; }

# --- 1. State-Dir anlegen wenn fehlt ----------------------------------------
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

# --- 2. Lock (verhindert dass 2 watchdogs parallel laufen) -------------------
exec 9>"$LOCK_FILE"
flock -n 9 || { log 'lock busy, exit'; exit 0; }

# --- 3. .env lesen (ohne sourcen, ohne loggen) ------------------------------
if [ ! -f "$ENV_FILE" ]; then
    log "fail .env missing: $ENV_FILE"
    exit 0
fi
TOKEN="$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"
CHAT="$(grep -E '^WATCHDOG_CHAT_ID=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"
if [ -z "$CHAT" ]; then
    # Fallback: erste ID aus TELEGRAM_ALLOWED_USER_IDS
    CHAT="$(grep -E '^TELEGRAM_ALLOWED_USER_IDS=' "$ENV_FILE" | head -n1 | cut -d= -f2- | cut -d, -f1)"
fi
if [ -z "$TOKEN" ] || [ -z "$CHAT" ]; then
    log 'fail telegram cfg missing (TOKEN or CHAT)'
    exit 0
fi

# --- 4. Health Check --------------------------------------------------------
if docker exec zf-bot wget -qO- --timeout=5 http://127.0.0.1:8080/healthz 2>/dev/null \
   | grep -q '"ok":true'; then
    HEALTH='ok'
else
    HEALTH='fail'
fi

# --- 5. Counter + Notify ----------------------------------------------------
count=0
[ -f "$FAIL_FILE" ] && count=$(cat "$FAIL_FILE" 2>/dev/null || echo 0)

send_telegram() {
    local text="$1"
    # silent: kein curl-Verbose, kein response loggen
    curl -s -o /dev/null -m 10 \
        --data-urlencode "chat_id=$CHAT" \
        --data-urlencode "text=$text" \
        "https://api.telegram.org/bot${TOKEN}/sendMessage" || true
}

if [ "$HEALTH" = 'fail' ]; then
    count=$((count + 1))
    echo "$count" >"$FAIL_FILE"
    log "fail $count/$THRESHOLD"
    if [ "$count" -ge "$THRESHOLD" ] && [ ! -f "$NOTIFIED_FLAG" ]; then
        send_telegram "[zf-watchdog] zf-bot down (3x consecutive fail)."
        : >"$NOTIFIED_FLAG"
        log 'alert sent'
    fi
else
    if [ -f "$NOTIFIED_FLAG" ]; then
        send_telegram '[zf-watchdog] zf-bot recovered.'
        rm -f "$NOTIFIED_FLAG"
        log 'recovery sent'
    fi
    : >"$FAIL_FILE"   # reset counter
    log 'ok'
fi
