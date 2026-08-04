#!/bin/bash
# ============================================================
#  PI SSH SETUP  -  Raspberry Pi im Netzwerk finden + SSH einrichten
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PI_SSH_SETUP.command
#  Sucht den Pi per mDNS (Bonjour), legt bei Bedarf einen SSH-Key
#  an (nie einen vorhandenen ueberschreiben), traegt einen Host-
#  Alias "raspi" in ~/.ssh/config ein (idempotent - doppelte
#  Eintraege werden nicht angelegt), bietet ssh-copy-id an.
# ============================================================
set -uo pipefail
echo "============================================================"
echo "  PI SSH SETUP"
echo "============================================================"

ALIAS="raspi"
SSHDIR="$HOME/.ssh"
CONFIG="$SSHDIR/config"
mkdir -p "$SSHDIR"
chmod 700 "$SSHDIR"

# --- 1) Pi im Netzwerk suchen ------------------------------------
echo
echo "--- Suche Raspberry Pi im Netzwerk ---"
FOUND_HOST=""
for h in raspberrypi.local raspberrypi2.local raspberrypi-2.local; do
  if ping -c1 -t2 "$h" >/dev/null 2>&1; then
    FOUND_HOST="$h"
    echo "  [OK] Gefunden ueber mDNS: $h"
    break
  fi
done

if [ -z "$FOUND_HOST" ]; then
  echo "  [*] Standard-Hostnamen nicht erreichbar - suche per Bonjour (SSH-Dienste) ..."
  TMP=$(mktemp)
  dns-sd -B _ssh._tcp local. > "$TMP" 2>/dev/null &
  DPID=$!
  sleep 5
  kill "$DPID" 2>/dev/null
  echo "  Gefundene SSH-Dienste im Netzwerk:"
  grep -E "^\s*[0-9]" "$TMP" | awk '{ $1=$2=$3=$4=""; print "   -", $0 }' | sed 's/^ *//'
  rm -f "$TMP"
  echo
  echo "  Falls dein Pi oben auftaucht: Namen/IP direkt unten eintippen."
fi

if [ -z "$FOUND_HOST" ]; then
  read -r -p "  Hostname oder IP des Raspberry Pi: " FOUND_HOST
fi
if [ -z "$FOUND_HOST" ]; then
  echo "  [X] Kein Ziel angegeben. Abbruch."
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
echo "  Ziel: $FOUND_HOST"

# --- 2) Benutzername ----------------------------------------------
read -r -p "  SSH-Benutzername auf dem Pi (z.B. der bei der Ersteinrichtung vergebene): " PI_USER
if [ -z "$PI_USER" ]; then
  echo "  [X] Kein Benutzername angegeben. Abbruch."
  read -r -p "[Enter] zum Schliessen "; exit 1
fi

# --- 3) SSH-Key sicherstellen (nie ueberschreiben) -----------------
KEY="$SSHDIR/id_ed25519"
if [ -f "$KEY" ]; then
  echo "  [OK] SSH-Key existiert bereits: $KEY (wird verwendet, nicht ueberschrieben)"
else
  echo "  [*] Kein Key gefunden - erstelle neuen (ed25519) ..."
  ssh-keygen -t ed25519 -f "$KEY" -C "mac-to-raspi-$(date +%Y%m%d)"
fi

# --- 4) Host-Eintrag in ~/.ssh/config (idempotent) -----------------
touch "$CONFIG"; chmod 600 "$CONFIG"
if grep -q "^Host $ALIAS\$" "$CONFIG" 2>/dev/null; then
  echo "  [OK] Host-Eintrag '$ALIAS' existiert bereits in $CONFIG - unveraendert gelassen."
else
  {
    echo ""
    echo "Host $ALIAS"
    echo "    HostName $FOUND_HOST"
    echo "    User $PI_USER"
    echo "    IdentityFile $KEY"
    echo "    StrictHostKeyChecking accept-new"
  } >> "$CONFIG"
  echo "  [OK] Host-Eintrag '$ALIAS' hinzugefuegt -> $CONFIG"
fi

# --- 5) Key auf den Pi kopieren (einmalig Passwort noetig) ---------
echo
read -r -p "  Jetzt Key auf den Pi kopieren (einmalig Passwort noetig)? [j/N] " COPY
if [ "$COPY" = "j" ] || [ "$COPY" = "J" ] || [ "$COPY" = "ja" ]; then
  ssh-copy-id -i "${KEY}.pub" "${PI_USER}@${FOUND_HOST}"
fi

# --- 6) Verbindung testen ------------------------------------------
echo
echo "--- Verbindungstest: ssh $ALIAS ---"
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$ALIAS" 'echo "[OK] Verbunden als $(whoami) auf $(hostname)"' 2>/dev/null; then
  echo "  Erfolgreich - ab jetzt reicht:  ssh $ALIAS"
else
  echo "  [!] Kein passwortloser Login moeglich (Key evtl. noch nicht kopiert)."
  echo "      Falls oben 'Key kopieren' uebersprungen wurde: einmal manuell"
  echo "      ausfuehren:  ssh-copy-id -i ${KEY}.pub ${PI_USER}@${FOUND_HOST}"
  echo "      Danach normal verbinden mit:  ssh $ALIAS"
fi

read -r -p $'\n[Enter] zum Schliessen '
