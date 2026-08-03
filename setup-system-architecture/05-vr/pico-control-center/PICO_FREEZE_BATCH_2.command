#!/bin/bash
# ============================================================
#  PICO FREEZE BATCH 2  -  ungenutzte Werkzeug-Apps einfrieren
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_FREEZE_BATCH_2.command
#  Reversibel: pm disable-user, KEINE Deinstallation.
#  Rueckgaengig jederzeit: PICO_CONTROL_CENTER.py -> Punkt 13.
# ============================================================
echo "============================================================"
echo "  PICO FREEZE BATCH 2"
echo "============================================================"

ADB=""
if command -v adb >/dev/null 2>&1; then ADB="$(command -v adb)"
elif [ -x "$HOME/platform-tools/adb" ]; then ADB="$HOME/platform-tools/adb"
elif [ -x "/opt/homebrew/bin/adb" ]; then ADB="/opt/homebrew/bin/adb"
elif [ -x "$HOME/PicoSetup/01_TOOLS/adb/adb" ]; then ADB="$HOME/PicoSetup/01_TOOLS/adb/adb"
fi
if [ -z "$ADB" ] || [ ! -x "$ADB" ]; then
  echo "[X] ADB nicht gefunden."
  read -r -p "[Enter] zum Schliessen "; exit 1
fi
echo "[OK] ADB: $ADB"

PKGS="com.esimgo.mobile com.foxdebug.acode com.github.catfriend1.syncthingfork com.larksuite.suite"

echo
echo "Werden eingefroren (reversibel, NICHT geloescht):"
for p in $PKGS; do echo "  - $p"; done
echo
echo "NICHT dabei (bewusst behalten): de.gerrit.placebook, com.termux,"
echo "com.x8bit.bitwarden, org.kde.kdeconnect_tp, YouTube VR, com.Dejevis.iLauncher (gesperrt)."
echo
read -r -p "Tippe JA zum Bestaetigen: " OK
if [ "$OK" != "JA" ]; then
  echo "Abgebrochen. Nichts veraendert."
  read -r -p "[Enter] zum Schliessen "
  exit 0
fi

mkdir -p "$HOME/PicoSetup/99_REPORTS_LOGS"
LOGFILE="$HOME/PicoSetup/99_REPORTS_LOGS/eingefroren.txt"
FAILS=""
for p in $PKGS; do
  OUT=$("$ADB" shell pm disable-user --user 0 "$p" 2>&1)
  if printf '%s' "$OUT" | grep -qi "disabled\|new state"; then
    printf '%s\tFREEZE\t%s\n' "$(date +%Y-%m-%d_%H-%M-%S)" "$p" >> "$LOGFILE"
    echo "  [OK] eingefroren: $p"
  else
    echo "  [X] fehlgeschlagen: $p ($OUT)"
    FAILS="$FAILS $p"
  fi
done

echo
echo "Fertig. Log: $LOGFILE"
[ -n "$FAILS" ] && echo "[!] Nicht eingefroren:$FAILS"
echo "Rueckgaengig jederzeit: PICO_CONTROL_CENTER.py -> Punkt 13 (App AUFTAUEN)."
read -r -p "[Enter] zum Schliessen "
