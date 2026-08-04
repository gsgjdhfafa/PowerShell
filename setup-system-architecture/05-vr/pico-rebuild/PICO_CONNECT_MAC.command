#!/bin/bash
# ============================================================
#  PICO CONNECT (Mac)  -  starten + Konfig-Ort anzeigen
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/PICO_CONNECT_MAC.command
#
#  Ehrlicher Hinweis: PICO Connect hat KEIN dokumentiertes CLI/
#  Terminal-Interface fuer Einstellungen (Bitrate, Aufloesung,
#  Tracking-Modus). Das geht nur ueber die App-eigene Oberflaeche.
#  Dieses Skript kann die App starten und dir zeigen, wo macOS
#  ihre Einstellungen (Preferences) ablegt - mehr ist von aussen
#  nicht sauber steuerbar, ohne inoffizielle/undokumentierte
#  Interna zu raten.
# ============================================================
echo "============================================================"
echo "  PICO CONNECT (Mac)"
echo "============================================================"

APP="/Applications/PICO Connect.app"
if [ -d "$APP" ]; then
  echo "[OK] Gefunden: $APP"
  open -a "PICO Connect"
  echo "[OK] Gestartet."
else
  echo "[!] Nicht gefunden unter $APP"
  echo "    Kostenlos: https://www.picoxr.com/global/software/pico-connect"
fi

echo
echo "--- Einstellungen (Preferences) - nur zur Info, GUI-Bearbeitung empfohlen ---"
BUNDLE_ID="com.picoxr.picoconnect"
PLIST="$HOME/Library/Preferences/${BUNDLE_ID}.plist"
if [ -f "$PLIST" ]; then
  echo "  Gefunden: $PLIST"
  echo "  Anzeigen (read-only):  defaults read $BUNDLE_ID"
else
  echo "  Keine Preferences-Datei unter der erwarteten Bundle-ID gefunden"
  echo "  ($BUNDLE_ID) - Bundle-ID kann je nach Version abweichen."
fi

cat <<'EOF'

Was per Terminal wirklich sauber geht:
  - App starten:            open -a "PICO Connect"
  - App beenden:             osascript -e 'quit app "PICO Connect"'
  - Preferences ansehen:     defaults read com.picoxr.picoconnect

Was NICHT per Terminal geht (nur in der App selbst):
  - Streaming-Qualitaet/Bitrate, Aufloesung, Tracking-Modus,
    virtuelle Monitor-Anzahl/-Anordnung.
  Diese Einstellungen liegen im Zahnrad-Menu der PICO Connect App,
  nachdem die Brille per WLAN (gleiches Netz) oder USB verbunden ist.
EOF
read -r -p "[Enter] zum Schliessen "
