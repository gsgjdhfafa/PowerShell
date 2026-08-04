#!/bin/bash
# ============================================================
#  PICO SPACE SETUP  -  Umgebungsaufzeichnung / Raum scannen
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_SPACE_SETUP.command
#  Oeffnet die Settings in der Brille per ADB. Das eigentliche
#  Scannen (Wand-/Bodenerkennung per Kamera) geht NUR im Headset -
#  nicht automatisierbar.
# ============================================================
echo "============================================================"
echo "  PICO SPACE SETUP"
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

LINE=$("$ADB" devices | awk 'NR>1 && $1!="" {print $2; exit}')
if [ "$LINE" != "device" ]; then
  echo "[X] Keine autorisierte PICO gefunden (USB pruefen / Popup im Headset bestaetigen)."
  "$ADB" devices
  read -r -p "[Enter] zum Schliessen "; exit 1
fi

"$ADB" shell am start -a android.settings.SETTINGS >/dev/null 2>&1
echo "[OK] Settings in der Brille geoeffnet."

cat <<'EOF'

Naechste Schritte IM HEADSET:
  1. Einstellungen -> Allgemein -> "Physischer Raum" / "Play Area" /
     "Space Setup" (Bezeichnung variiert je nach PICO-OS-Version).
  2. Neuen Raum einrichten -> mit dem Controller die Boden-/Wandgrenze
     abfahren, bis der Scan abgeschlossen ist.
  3. Bildschirme/Fenster an Waende pinnen: in MR-faehigen Apps
     (z.B. PICO Connect fuer virtuelle Monitore) nach dem Scan verfuegbar.
  4. Objekte "funktionalisieren" (z.B. Papierkorb als Trigger/Anker):
     im Menu "Mixed Reality" / "Anker" bzw. "Spatial Anchors" - variiert
     je nach Firmware, aktuell keine ADB-Automatisierung moeglich.

EOF
read -r -p "[Enter] zum Schliessen "
