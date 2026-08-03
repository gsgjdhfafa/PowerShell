#!/bin/bash
# ============================================================
#  PICO FREEZE BATCH  -  friert bestaetigte Kandidaten ein
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_FREEZE_BATCH.command
#  Reversibel: pm disable-user, KEINE Deinstallation.
#  Rueckgaengig jederzeit: PICO_CONTROL_CENTER.py -> Punkt 13.
# ============================================================
echo "============================================================"
echo "  PICO FREEZE BATCH"
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

PKGS="com.GWPro.HealthandSafetyTrainingBundlePico com.Raumkapsel.AlmasDisk_Episode1 com.resolutiongames.abvriop.demo com.Simlab.SimlabViewer com.ss.android.ttvr.global com.TriangleFactory.HyperDash com.vrdirect.vrplayer com.wwf.PowertoX_Short games.b4t.epicrollercoasters.pico.neo2"

echo
echo "Werden eingefroren (reversibel, NICHT geloescht):"
for p in $PKGS; do echo "  - $p"; done
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
