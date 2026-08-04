#!/bin/bash
# ============================================================
#  PICO REBUILD ALL  -  stellt den heutigen Endstand komplett wieder her
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_REBUILD_ALL.command
#  Fuer den Fall "PICO wurde zurueckgesetzt / neu aufgesetzt" -
#  ein einziges Skript reicht dann, um wieder auf den Stand vom
#  04.08.2026 zu kommen: 4 Ziel-Apps installieren, 13 bestaetigt
#  unnoetige Apps einfrieren, Login-/Dashboard-Seiten oeffnen.
#  Komplett eigenstaendig (keine anderen Dateien noetig).
#  Installiert nur / friert ein, loescht NICHTS. Alles reversibel.
# ============================================================
echo "============================================================"
echo "  PICO REBUILD ALL"
echo "============================================================"

# --- ADB sicherstellen ---------------------------------------
ADB=""
if command -v adb >/dev/null 2>&1; then ADB="$(command -v adb)"
elif [ -x "$HOME/platform-tools/adb" ]; then ADB="$HOME/platform-tools/adb"
elif [ -x "/opt/homebrew/bin/adb" ]; then ADB="/opt/homebrew/bin/adb"
elif [ -x "$HOME/PicoSetup/01_TOOLS/adb/adb" ]; then ADB="$HOME/PicoSetup/01_TOOLS/adb/adb"
else
  echo "[*] Lade Android Platform-Tools (ADB) ..."
  cd "$HOME" || exit 1
  curl -sL -o platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
  unzip -oq platform-tools.zip
  ADB="$HOME/platform-tools/adb"
fi
if [ ! -x "$ADB" ]; then
  echo "[X] ADB konnte nicht bereitgestellt werden."
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
echo "[OK] ADB: $ADB"

# --- Verbinden --------------------------------------------------
"$ADB" start-server >/dev/null 2>&1
echo "[*] Warte auf die PICO ... (Popup 'USB-Debugging zulassen' IM Headset bestaetigen)"
STATE=""
for i in $(seq 1 25); do
  LINE=$("$ADB" devices | awk 'NR>1 && $1!="" {print $2; exit}')
  if [ "$LINE" = "device" ]; then STATE="device"; break; fi
  if [ "$LINE" = "unauthorized" ]; then echo "    -> Bitte Popup im Headset bestaetigen ..."; fi
  sleep 2
done
if [ "$STATE" != "device" ]; then
  echo "[X] Keine autorisierte PICO gefunden."
  "$ADB" devices
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
MODEL=$("$ADB" shell getprop ro.product.model | tr -d '\r')
echo "[OK] Verbunden: $MODEL"

# --- 1) Ziel-Apps installieren -----------------------------------
gh_url () { # $1=repo $2=match-regex
  curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.apk"' \
    | sed 's/.*"\(http[^"]*\)"/\1/' | grep -Ei "$2" | head -1
}
install_url () { # $1=name $2=pkg $3=url
  local n="$1" p="$2" u="$3"
  if "$ADB" shell pm list packages "$p" 2>/dev/null | tr -d '\r' | grep -qx "package:$p"; then
    echo "  [OK] $n: schon installiert"; return
  fi
  [ -z "$u" ] && { echo "  [!] $n: keine URL gefunden"; return; }
  echo "  [*] Lade $n ..."
  curl -sL "$u" -o "/tmp/$n.apk" || { echo "  [X] $n: Download-Fehler"; return; }
  if "$ADB" install -r "/tmp/$n.apk" >/dev/null 2>&1; then echo "  [OK] $n: installiert"; else echo "  [X] $n: Install-Fehler"; fi
}
echo
echo "--- [1/3] Ziel-Apps installieren ---"
install_url Telegram org.telegram.messenger.web "https://telegram.org/dl/android/apk"
install_url VLC org.videolan.vlc "https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk"
install_url Brave  com.brave.browser  "$(gh_url brave/brave-browser 'arm64|universal')"
install_url Wolvic com.igalia.wolvic  "$(gh_url Igalia/wolvic 'arm64|noapi')"

# --- 2) Bestaetigt unnoetige Apps einfrieren ----------------------
# Genau die 13 Apps, die am 04.08.2026 im Chat zweifach bestaetigt wurden.
# NICHT dabei (bewusst behalten): Termux, Bitwarden, KDE Connect,
# YouTube VR, de.gerrit.placebook (eigenes Projekt), iLauncher (gesperrt).
FREEZE_PKGS="com.GWPro.HealthandSafetyTrainingBundlePico com.Raumkapsel.AlmasDisk_Episode1 com.resolutiongames.abvriop.demo com.Simlab.SimlabViewer com.ss.android.ttvr.global com.TriangleFactory.HyperDash com.vrdirect.vrplayer com.wwf.PowertoX_Short games.b4t.epicrollercoasters.pico.neo2 com.esimgo.mobile com.foxdebug.acode com.github.catfriend1.syncthingfork com.larksuite.suite"

echo
echo "--- [2/3] Bestaetigte Kandidaten einfrieren (reversibel) ---"
mkdir -p "$HOME/PicoSetup/99_REPORTS_LOGS"
LOGFILE="$HOME/PicoSetup/99_REPORTS_LOGS/eingefroren.txt"
for p in $FREEZE_PKGS; do
  # Nur einfrieren, wenn ueberhaupt installiert (frischer Reset hat sie evtl. gar nicht)
  if "$ADB" shell pm list packages "$p" 2>/dev/null | tr -d '\r' | grep -qx "package:$p"; then
    OUT=$("$ADB" shell pm disable-user --user 0 "$p" 2>&1)
    if printf '%s' "$OUT" | grep -qi "disabled\|new state"; then
      printf '%s\tFREEZE\t%s\n' "$(date +%Y-%m-%d_%H-%M-%S)" "$p" >> "$LOGFILE"
      echo "  [OK] eingefroren: $p"
    else
      echo "  [X] fehlgeschlagen: $p ($OUT)"
    fi
  else
    echo "  [-] nicht vorhanden (uebersprungen): $p"
  fi
done

# --- 3) Login-/Dashboard-Seiten oeffnen ---------------------------
echo
echo "--- [3/3] Login-/Dashboard-Seiten oeffnen ---"
for u in \
  "https://www.notion.so/login" \
  "https://mail.google.com" \
  "https://calendar.google.com" \
  "https://tasks.google.com" \
  "https://web.telegram.org"; do
  "$ADB" shell am start -a android.intent.action.VIEW -d "$u" >/dev/null 2>&1
  echo "  offen: $u"
done

echo
echo "============================================================"
echo "  FERTIG - Stand vom 04.08.2026 wiederhergestellt."
echo "  Naechstes: Telegram einloggen -> /start an den Bot."
echo "============================================================"
read -r -p "[Enter] zum Schliessen "
