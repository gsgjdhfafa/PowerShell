#!/bin/bash
# ============================================================
#  PICO 1-Klick (Linux)  -  verbinden + kluge Apps + Zugaenge
#  Nutzung:   bash ~/Downloads/PICO_LINUX.sh
#  Installiert nur, loescht nichts.
# ============================================================
echo "============================================================"
echo "  PICO 1-KLICK (Linux)"
echo "============================================================"

# --- 1) ADB sicherstellen -----------------------------------
ADB=""
if command -v adb >/dev/null 2>&1; then
  ADB="$(command -v adb)"
elif [ -x "$HOME/platform-tools/adb" ]; then
  ADB="$HOME/platform-tools/adb"
else
  echo "[*] ADB nicht gefunden - versuche Paketmanager ..."
  if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update -y && sudo apt-get install -y android-tools-adb || sudo apt-get install -y adb
  elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y android-tools
  elif command -v pacman  >/dev/null 2>&1; then sudo pacman -Sy --noconfirm android-tools
  fi
  if command -v adb >/dev/null 2>&1; then
    ADB="$(command -v adb)"
  else
    echo "[*] Paketweg klappte nicht - lade Platform-Tools (x86_64) ..."
    cd "$HOME" || exit 1
    curl -sL -o platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-linux.zip
    if command -v unzip >/dev/null 2>&1; then unzip -oq platform-tools.zip
    else python3 -c "import zipfile;zipfile.ZipFile('platform-tools.zip').extractall('$HOME')"; fi
    ADB="$HOME/platform-tools/adb"
    chmod +x "$ADB" 2>/dev/null
  fi
fi
if [ ! -x "$ADB" ] && ! command -v "$ADB" >/dev/null 2>&1; then
  echo "[X] ADB konnte nicht bereitgestellt werden."
  echo "    Tipp (ARM/Banana Pi): 'sudo apt install android-tools-adb'"
  read -r -p "[Enter] "; exit 1
fi
echo "[OK] ADB: $ADB"

# --- 2) Verbinden -------------------------------------------
"$ADB" kill-server >/dev/null 2>&1
"$ADB" start-server >/dev/null 2>&1
echo "[*] Warte auf die Brille ... (Popup 'USB-Debugging zulassen' IM Headset bestaetigen)"
STATE=""
for i in $(seq 1 25); do
  LINE=$("$ADB" devices | awk 'NR>1 && $1!="" {print $2; exit}')
  [ "$LINE" = "device" ] && { STATE="device"; break; }
  [ "$LINE" = "unauthorized" ] && echo "    -> Popup im Headset bestaetigen ..."
  sleep 2
done
if [ "$STATE" != "device" ]; then
  echo "[X] Keine autorisierte Pico gefunden."
  echo "    Pruefe: DATENkabel (nicht nur laden)? Popup bestaetigt? Ohne USB-Hub?"
  echo "    Linux-Extra: evtl. udev-Rechte noetig ('plugdev'-Gruppe / sudo)."
  "$ADB" devices
  read -r -p "[Enter] "; exit 1
fi
MODEL=$("$ADB" shell getprop ro.product.model | tr -d '\r')
echo "[OK] Verbunden: $MODEL"

# --- 3) Kuratierte Apps -------------------------------------
gh_url () {
  curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.apk"' \
    | sed 's/.*"\(http[^"]*\)"/\1/' | grep -Ei "$2" | head -1
}
install_url () {
  local n="$1" p="$2" u="$3"
  if "$ADB" shell pm list packages "$p" 2>/dev/null | tr -d '\r' | grep -qx "package:$p"; then echo "  [OK] $n: schon da"; return; fi
  [ -z "$u" ] && { echo "  [!] $n: keine URL"; return; }
  echo "  [*] Lade $n ..."
  curl -sL "$u" -o "/tmp/$n.apk" || { echo "  [X] $n: Download-Fehler"; return; }
  if "$ADB" install -r "/tmp/$n.apk" >/dev/null 2>&1; then echo "  [OK] $n: installiert"; else echo "  [X] $n: Install-Fehler"; fi
}
echo "--- Apps installieren ---"
install_url Telegram org.telegram.messenger.web "https://telegram.org/dl/android/apk"
install_url VLC org.videolan.vlc "https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk"
install_url Brave  com.brave.browser  "$(gh_url brave/brave-browser 'arm64|universal')"
install_url Wolvic com.igalia.wolvic  "$(gh_url Igalia/wolvic 'arm64|noapi')"

# --- 4) Login-/Dashboard-Seiten -----------------------------
echo "--- Login-/Dashboard-Seiten auf der Brille oeffnen ---"
for u in \
  "https://www.notion.so/login" \
  "https://mail.google.com" \
  "https://calendar.google.com" \
  "https://tasks.google.com" \
  "https://web.telegram.org"; do
  "$ADB" shell am start -a android.intent.action.VIEW -d "$u" >/dev/null 2>&1
  echo "  offen: $u"
done

echo "============================================================"
echo "  FERTIG - in der Brille:"
echo "   1. Telegram -> einloggen -> /start an deinen Bot -> Mikro = Voice->Notion"
echo "   2. Browser: 5 Tabs offen -> einloggen -> Lesezeichen setzen"
echo "   3. Multi-Monitor: PICO Connect starten"
echo "============================================================"
read -r -p "[Enter] zum Schliessen "
