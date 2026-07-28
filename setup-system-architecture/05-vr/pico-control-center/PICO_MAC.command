#!/bin/bash
# ============================================================
#  PICO 1-Klick (macOS)  -  verbinden + kluge Apps + Zugaenge
#  Nutzung:  im Terminal ->   bash ~/Downloads/PICO_MAC.command
#  Installiert nur, loescht nichts.
# ============================================================
echo "============================================================"
echo "  PICO 1-KLICK (macOS)"
echo "============================================================"

# --- 1) ADB sicherstellen -----------------------------------
ADB=""
if command -v adb >/dev/null 2>&1; then ADB="$(command -v adb)"
elif [ -x "$HOME/platform-tools/adb" ]; then ADB="$HOME/platform-tools/adb"
else
  echo "[*] Lade Android Platform-Tools (ADB) ..."
  cd "$HOME" || exit 1
  curl -sL -o platform-tools.zip https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
  unzip -oq platform-tools.zip
  ADB="$HOME/platform-tools/adb"
fi
if [ ! -x "$ADB" ]; then echo "[X] ADB konnte nicht bereitgestellt werden."; read -r -p "[Enter] "; exit 1; fi
echo "[OK] ADB: $ADB"

# --- 2) Verbinden -------------------------------------------
"$ADB" kill-server >/dev/null 2>&1
"$ADB" start-server >/dev/null 2>&1
echo "[*] Warte auf die Brille ... (Popup 'USB-Debugging zulassen' IM Headset bestaetigen)"
STATE=""
for i in $(seq 1 25); do
  LINE=$("$ADB" devices | awk 'NR>1 && $1!="" {print $2; exit}')
  if [ "$LINE" = "device" ]; then STATE="device"; break; fi
  if [ "$LINE" = "unauthorized" ]; then echo "    -> Bitte Popup im Headset bestaetigen ..."; fi
  sleep 2
done
if [ "$STATE" != "device" ]; then
  echo "[X] Keine autorisierte Pico gefunden."
  echo "    Pruefe: DATENkabel (nicht nur laden)? Popup im Headset bestaetigt? Direkt am Mac (ohne Hub)?"
  "$ADB" devices
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
MODEL=$("$ADB" shell getprop ro.product.model | tr -d '\r')
echo "[OK] Verbunden: $MODEL"

# --- 3) Kuratierte Apps -------------------------------------
gh_url () { # $1=repo  $2=regex
  curl -s "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*\.apk"' \
    | sed 's/.*"\(http[^"]*\)"/\1/' | grep -Ei "$2" | head -1
}
install_url () { # $1=name $2=pkg $3=url
  local n="$1" p="$2" u="$3"
  if "$ADB" shell pm list packages "$p" 2>/dev/null | grep -q "$p"; then echo "  [OK] $n: schon installiert"; return; fi
  [ -z "$u" ] && { echo "  [!] $n: keine URL gefunden"; return; }
  echo "  [*] Lade $n ..."
  curl -sL "$u" -o "/tmp/$n.apk" || { echo "  [X] $n: Download-Fehler"; return; }
  if "$ADB" install -r "/tmp/$n.apk" >/dev/null 2>&1; then echo "  [OK] $n: installiert"; else echo "  [X] $n: Install-Fehler"; fi
}
echo "--- Apps installieren ---"
install_url Telegram org.telegram.messenger "https://telegram.org/dl/android/apk"
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
echo "  FERTIG - jetzt in der Brille:"
echo "   1. Telegram oeffnen -> einloggen -> /start an deinen Bot"
echo "      -> Mikro-Button = Voice-Diktat -> landet in Notion"
echo "   2. Browser: 5 Tabs sind offen -> einloggen -> Lesezeichen setzen"
echo "   3. Multi-Monitor: PICO Connect am Mac starten"
echo "============================================================"
read -r -p "[Enter] zum Schliessen "
