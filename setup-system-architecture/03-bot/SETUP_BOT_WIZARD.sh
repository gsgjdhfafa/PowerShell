#!/usr/bin/env bash
# ============================================================
#  BOT SETUP WIZARD  -  kompletter Bot-Aufbau in einem Lauf
# ============================================================
#  Ausfuehren als root, im geklonten Repo:
#    bash setup-system-architecture/03-bot/SETUP_BOT_WIZARD.sh
#
#  Zieht automatisch durch: System-Basis, Docker, Absicherung,
#  Bot-Deploy, Erreichbarkeits-Test.
#  Haelt NUR an den kritischen, nicht automatisierbaren Punkten an:
#    - SSH-Haertung (Aussperr-Risiko -> Bestaetigung noetig)
#    - API-Tokens/Keys (koennen nicht erraten werden)
#  Idempotent: erneuter Lauf ueberschreibt keine vorhandene .env.
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOTDIR="$ROOT/03-bot"
ENVFILE="$BOTDIR/.env"

step() { echo; echo "============================================================"; echo "  $1"; echo "============================================================"; }
ask()        { local p="$1"; local r; read -rp "$p" r; echo "$r"; }
ask_secret() { local p="$1"; local r; read -rsp "$p" r; echo >&2; echo "$r"; }

if [ "$(id -u)" -ne 0 ]; then
    echo "[X] Bitte als root ausfuehren (sudo bash SETUP_BOT_WIZARD.sh)."
    exit 1
fi

step "1/6  System-Basis (Pakete, Zeitzone, User 'ops')"
bash "$ROOT/02-server/01-base.sh"

step "2/6  Docker + Node.js + Git"
bash "$ROOT/02-server/02-docker.sh"

step "3/6  Absicherung (SSH, Firewall, fail2ban)  -  KRITISCH"
echo "  Danach: kein Passwort-Login mehr, kein root-SSH mehr."
echo "  Schritt 1 hat deinen SSH-Key bereits nach /home/ops/.ssh/authorized_keys kopiert"
echo "  (aus /root/.ssh/authorized_keys). Trotzdem: bitte NICHT diese Sitzung schliessen,"
echo "  bis du dich einmal erfolgreich als 'ops' per SSH-Key eingeloggt hast."
CONFIRM=$(ask "  SSH-Key-Zugang fuer 'ops' vorhanden/bestaetigt? Tippe JA: ")
if [ "$CONFIRM" = "JA" ]; then
    bash "$ROOT/02-server/03-hardening.sh"
else
    echo "  [!] Uebersprungen (kein Risiko eingegangen)."
    echo "      Spaeter manuell: bash 02-server/03-hardening.sh"
fi

step "4/6  Zugangsdaten (.env)  -  KRITISCH, nicht automatisierbar"
if [ -f "$ENVFILE" ]; then
    echo "  [OK] .env existiert bereits -> wird NICHT ueberschrieben."
    echo "       Zum Aendern: $ENVFILE manuell bearbeiten, danach deploy.sh erneut."
else
    cp "$BOTDIR/.env.example" "$ENVFILE"
    echo "  Einmalig ausfuellen (Enter = leer lassen, spaeter in $ENVFILE nachtragen):"
    TG_TOKEN=$(ask_secret     "  TELEGRAM_BOT_TOKEN (von @BotFather): ")
    TG_UID=$(ask              "  TELEGRAM_ALLOWED_USER_ID (deine Telegram-User-ID, von @userinfobot): ")
    NOTION_TOKEN=$(ask_secret "  NOTION_TOKEN (Integration Secret): ")
    NOTION_MEM=$(ask          "  NOTION_DB_MEMORY (Datenbank-ID): ")
    NOTION_TASK=$(ask         "  NOTION_DB_TASKS (Datenbank-ID): ")
    NOTION_COST=$(ask         "  NOTION_DB_COSTS (Datenbank-ID): ")
    ANTH_KEY=$(ask_secret     "  ANTHROPIC_API_KEY (primaer, empfohlen): ")
    OPENAI_KEY=$(ask_secret   "  OPENAI_API_KEY (Fallback, optional): ")

    sed -i "s|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=$TG_TOKEN|"           "$ENVFILE"
    sed -i "s|^TELEGRAM_ALLOWED_USER_ID=.*|TELEGRAM_ALLOWED_USER_ID=$TG_UID|" "$ENVFILE"
    sed -i "s|^NOTION_TOKEN=.*|NOTION_TOKEN=$NOTION_TOKEN|"                   "$ENVFILE"
    sed -i "s|^NOTION_DB_MEMORY=.*|NOTION_DB_MEMORY=$NOTION_MEM|"             "$ENVFILE"
    sed -i "s|^NOTION_DB_TASKS=.*|NOTION_DB_TASKS=$NOTION_TASK|"              "$ENVFILE"
    sed -i "s|^NOTION_DB_COSTS=.*|NOTION_DB_COSTS=$NOTION_COST|"              "$ENVFILE"
    [ -n "$ANTH_KEY" ]   && sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTH_KEY|" "$ENVFILE"
    [ -n "$OPENAI_KEY" ] && sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$OPENAI_KEY|"     "$ENVFILE"
    chmod 600 "$ENVFILE"
    echo "  [OK] .env geschrieben (chmod 600, nie im Git)."
fi

step "5/6  Bot deployen (Docker Build + Start)"
bash "$BOTDIR/deploy.sh"

step "6/6  Erreichbarkeits-Test"
TOKEN=$(grep '^TELEGRAM_BOT_TOKEN=' "$ENVFILE" | cut -d= -f2-)
UNAME=""
if [ -n "$TOKEN" ]; then
    ME=$(curl -fsS "https://api.telegram.org/bot${TOKEN}/getMe" || true)
    if command -v jq >/dev/null 2>&1 && echo "$ME" | jq -e '.ok' >/dev/null 2>&1; then
        UNAME=$(echo "$ME" | jq -r '.result.username')
        echo "  [OK] Bot erreichbar: @$UNAME"
    else
        echo "  [X] Bot antwortet nicht auf getMe. Token in .env pruefen."
    fi
else
    echo "  [!] Kein Token in .env - Test uebersprungen."
fi

step "FERTIG"
echo "  Bot laeuft als Docker-Container 'ai-bridge-bot'."
echo
echo "  JETZT IN TELEGRAM PRUEFEN:"
if [ -n "$UNAME" ]; then echo "   1. @$UNAME suchen -> /start senden."
else                     echo "   1. Deinen Bot suchen -> /start senden."
fi
echo "   2. Kommt 'ready. /task /note /cost oder freier Text.' zurueck -> alles ok."
echo "   3. Keine Antwort? Live-Log pruefen:"
echo "        cd $BOTDIR && docker compose logs -f"
echo "      Dort steht bei jeder eingehenden Nachricht die Absender-ID."
echo "      Weicht sie von TELEGRAM_ALLOWED_USER_ID in .env ab -> dort korrigieren,"
echo "      dann erneut:  bash $BOTDIR/deploy.sh"
echo
echo "  Danach: /task /note /cost testen -> Eintrag muss in Notion auftauchen."
