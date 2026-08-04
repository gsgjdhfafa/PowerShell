#!/bin/bash
# ============================================================
#  PICO AUDIT (macOS)  -  was laeuft, was muss weg, was fehlt?
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_AUDIT_MAC.command
#  Reiner Scan (lesend). Aendert / loescht / friert NICHTS ein.
# ============================================================
echo "============================================================"
echo "  PICO AUDIT (macOS)"
echo "============================================================"

HOMESETUP="$HOME/PicoSetup"
LOGS="$HOMESETUP/99_REPORTS_LOGS"
mkdir -p "$LOGS"

# --- ADB sicherstellen ---------------------------------------
ADB=""
if command -v adb >/dev/null 2>&1; then ADB="$(command -v adb)"
elif [ -x "$HOME/platform-tools/adb" ]; then ADB="$HOME/platform-tools/adb"
elif [ -x "$HOMESETUP/01_TOOLS/adb/adb" ]; then ADB="$HOMESETUP/01_TOOLS/adb/adb"
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

# --- Verbindung pruefen ---------------------------------------
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
  echo "    Pruefe: DATENkabel (nicht nur laden)? Popup im Headset bestaetigt? Direkt am Mac (ohne Hub)?"
  "$ADB" devices
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
MODEL=$("$ADB" shell getprop ro.product.model | tr -d '\r')
VER=$("$ADB" shell getprop ro.build.version.release | tr -d '\r')
echo "[OK] $MODEL  Android $VER"

# --- Pakete lesen -----------------------------------------------
# -e = nur aktive (enabled), -d = nur eingefrorene (disabled).
# Wichtig: "pm list packages -3" ohne -e/-d zeigt AUCH eingefrorene Apps -
# die verschwinden durch Einfrieren nicht aus der Liste, nur aus dem Betrieb.
USERPKGS_ALL=$("$ADB" shell pm list packages -3    | sed 's/package://' | tr -d '\r' | sort)
USERPKGS=$("$ADB"      shell pm list packages -3 -e | sed 's/package://' | tr -d '\r' | sort)
USERPKGS_FROZEN=$("$ADB" shell pm list packages -3 -d | sed 's/package://' | tr -d '\r' | sort)
SYSPKGS=$("$ADB" shell pm list packages -s | sed 's/package://' | tr -d '\r' | sort)
ALLPKGS=$(printf '%s\n%s\n' "$USERPKGS_ALL" "$SYSPKGS" | sort -u)

# --- Kritisch = nie anfassen (Brick-Schutz) ---------------------
is_critical () {
  local pkg_lc
  pkg_lc=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$pkg_lc" in
    *launcher*|*systemui*|com.android.*|com.pico*|com.pvr*|com.picovr*|*vrshell*| \
    com.qualcomm*|*inputmethod*|com.google.android.gms|com.google.android.gsf| \
    com.google.android.gsm|*telephony*|*packageinstaller*|com.android.vending| \
    *provider*|com.oplus*|com.bytedance.picovr|*setup*|*keyguard*|com.pico4*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Unser kuratiertes Ziel-Setup (parallele Arrays, bash-3-kompatibel) ---
TARGET_PKGS=(org.telegram.messenger.web com.brave.browser org.videolan.vlc com.igalia.wolvic)
TARGET_NAMES=("Telegram (Voice -> Bot -> Notion)" "Brave (Dashboards/Bookmarks)" "VLC (Medien)" "Wolvic (XR-Browser)")

echo
echo "--- [1] ZIEL-APPS ---"
MISSING=""
for i in "${!TARGET_PKGS[@]}"; do
  p="${TARGET_PKGS[$i]}"; n="${TARGET_NAMES[$i]}"
  if printf '%s\n' "$ALLPKGS" | grep -qx "$p"; then
    echo "  [OK] $n ($p)"
  else
    echo "  [X ] $n ($p) - FEHLT"
    MISSING="$MISSING $p"
  fi
done

echo
echo "--- [2] KANDIDATEN ZUM EINFRIEREN (deine Apps, nicht Teil unseres Setups) ---"
CANDS=""
CANDCOUNT=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  is_target=0
  for t in "${TARGET_PKGS[@]}"; do [ "$p" = "$t" ] && is_target=1; done
  if [ "$is_target" -eq 0 ] && ! is_critical "$p"; then
    echo "  - $p"
    CANDS="$CANDS$p
"
    CANDCOUNT=$((CANDCOUNT+1))
  fi
done <<EOF
$USERPKGS
EOF
[ "$CANDCOUNT" -eq 0 ] && echo "  (keine - nichts Fremdes gefunden)"

FROZENCOUNT=$(printf '%s\n' "$USERPKGS_FROZEN" | grep -c . || true)
echo
echo "--- [3] BEREITS EINGEFROREN (deaktiviert, laeuft nicht) - $FROZENCOUNT App(s) ---"
if [ "$FROZENCOUNT" -gt 0 ]; then
  printf '%s\n' "$USERPKGS_FROZEN" | while IFS= read -r p; do [ -n "$p" ] && echo "  - $p"; done
else
  echo "  (keine)"
fi

# --- Report speichern ---------------------------------------------
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT="$LOGS/audit_mac_${STAMP}.txt"
{
  echo "PICO AUDIT $STAMP"
  echo "Modell: $MODEL  Android: $VER"
  echo
  echo "ZIEL-APPS:"
  for i in "${!TARGET_PKGS[@]}"; do echo "  ${TARGET_PKGS[$i]} - ${TARGET_NAMES[$i]}"; done
  echo
  echo "KANDIDATEN ZUM EINFRIEREN ($CANDCOUNT):"
  printf '%s' "$CANDS"
  echo
  echo "BEREITS EINGEFROREN ($FROZENCOUNT):"
  echo "$USERPKGS_FROZEN"
  echo
  echo "USER-APPS (alle, aktiv+eingefroren):"
  echo "$USERPKGS_ALL"
  echo
  echo "SYSTEM-APPS (alle):"
  echo "$SYSPKGS"
} > "$REPORT"

echo
echo "--- Report gespeichert: $REPORT ---"
if [ -n "$MISSING" ]; then
  echo "[!] Fehlende Ziel-Apps:$MISSING"
  echo "    Nachinstallieren: PICO_MAC.command erneut ausfuehren."
fi
if [ "$CANDCOUNT" -gt 0 ]; then
  echo "[!] $CANDCOUNT Kandidat(en) zum Einfrieren -> PICO_CONTROL_CENTER.py Punkt 12,"
  echo "    oder manuell: $ADB shell pm disable-user --user 0 <paket>"
else
  echo "[OK] Sauber: keine fremden User-Apps."
fi
if [ -z "$MISSING" ] && [ "$CANDCOUNT" -eq 0 ]; then
  echo "[OK] Alle Ziel-Apps vorhanden."
fi

read -r -p $'\n[Enter] zum Schliessen '
