#!/usr/bin/env bash
# Installiert den Watchdog als Cron-Job fuer User $APP_USER. Idempotent.
# Aufruf:  APP_USER=ops bash setup/2-server/install-watchdog.sh
set -euo pipefail

APP_USER="${APP_USER:-ops}"
APP_DIR="${APP_DIR:-/home/$APP_USER/app}"
WD_PATH="$APP_DIR/setup/2-server/watchdog.sh"
LOG_PATH='/var/log/zf-watchdog.log'
CRON_LINE="*/5 * * * * $WD_PATH >>$LOG_PATH 2>&1"

[ -f "$WD_PATH" ] || { echo "[!] $WD_PATH nicht gefunden."; exit 1; }

# --- 1. State-Dir + Logfile mit korrekten Rechten ---------------------------
install -d -m 700 -o "$APP_USER" -g "$APP_USER" /var/lib/zf-watchdog
install -m 640 -o "$APP_USER" -g "$APP_USER" /dev/null "$LOG_PATH" 2>/dev/null || true
chown "$APP_USER:$APP_USER" "$LOG_PATH" 2>/dev/null || true

# --- 2. logrotate-Regel (1 MB, keep 3) --------------------------------------
cat >/etc/logrotate.d/zf-watchdog <<EOF
$LOG_PATH {
    size 1M
    rotate 3
    missingok
    notifempty
    compress
    copytruncate
}
EOF

# --- 3. Cron-Eintrag idempotent setzen --------------------------------------
existing="$(crontab -u "$APP_USER" -l 2>/dev/null || true)"
if printf '%s\n' "$existing" | grep -qF 'watchdog.sh'; then
    echo '[ok] cron-eintrag fuer watchdog.sh existiert bereits.'
else
    { printf '%s\n' "$existing"; printf '%s\n' "$CRON_LINE"; } \
        | grep -v '^[[:space:]]*$' \
        | crontab -u "$APP_USER" -
    echo "[ok] cron-eintrag installiert: $CRON_LINE"
fi

# --- 4. Sanity: ein Erstlauf, damit der Status-Datei erzeugt wird -----------
sudo -u "$APP_USER" bash "$WD_PATH" || true
echo '[ok] watchdog initial run done.'
