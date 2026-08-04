# PICO Control Center

Einfaches, sicheres Toolkit, um die **PICO 4 Ultra** vom Windows-PC aus zu
verwalten. Nur kostenlose Tools (ADB, scrcpy, yt-dlp). Kein Kauf noetig.

**Prinzip:** klein anfangen, alles reversibel, nichts wird geloescht, die
VR-Aufloesung wird nicht veraendert. Bildschirm-Setups laufen PC-seitig
(scrcpy), Debloat = **Einfrieren** (`disable-user`) statt Loeschen.

## Dateien

| Datei | Zweck |
|-------|-------|
| `START_PICO_CONTROL_CENTER.py` | Einmal-Setup: Ordnerstruktur anlegen, ADB + PICO pruefen, optional scrcpy |
| `PICO_CONTROL_CENTER.py` | Menue (Modifikationsbasis): Status, WLAN-ADB, Live-Bild, Apps, Inventar, Einfrieren/Auftauen, Medien, Backup, Audit |
| `PICO_AUDIT.py` | Sofort-Scan (Doppelklick): was laeuft, was ist Kandidat zum Einfrieren, was fehlt vom Ziel-Setup |
| `PICO_AUDIT_MAC.command` | Gleicher Audit-Scan, reines Bash (kein Python), macOS-Doppelklick |
| `PICO_FREEZE_BATCH.command` / `PICO_FREEZE_BATCH_2.command` | Bestaetigte Freeze-Kandidaten in einem Rutsch einfrieren (`-y` fuer ohne Rueckfrage) |
| `PICO_SPACE_SETUP.command` | Shortcut zur Umgebungsaufzeichnung (Raum scannen) - oeffnet Settings in der Brille per ADB |
| `SYNC_TO_SHARED.py` | Kopiert das PicoSetup-Verzeichnis nach `<shared>\Picco` (nur additiv) |

## Nutzung

1. Ordner `C:\Users\Gerrit\PicoSetup` anlegen, die drei Skripte hineinlegen.
2. `START_PICO_CONTROL_CENTER.py` doppelklicken -> Struktur + Statuscheck.
3. `PICO_CONTROL_CENTER.py` doppelklicken -> Zahl tippen.

Benoetigte Tools (portabel, kostenlos) nach `01_TOOLS\` legen:
`adb\`, `scrcpy\`, `yt-dlp\`. ADB alternativ via `winget install Google.PlatformTools`.

## Menue (v2)

```
 1 Status              2 WLAN-ADB (ohne USB)
 3 Live: ein Auge      4 Live: voll        5 Live: sparsam
 6 Aufnehmen           7 PICO Connect
 8 Apps + Report       9 Voll-Inventar     10 APK installieren
11 App-APK sichern    12 App EINFRIEREN   13 App AUFTAUEN
14 Datei -> PICO      15 Screenshot       16 Video (yt-dlp)
17 Tools pruefen      18 Kopie -> shared\Picco
19 AUDIT (was laeuft / weg / fehlt)
20 Umgebungsaufzeichnung / Space Setup      0 Beenden
```

## Sicherheit

- Kritische System-/Pico-Pakete (Launcher, VR-Runtime, SystemUI, ...) sind
  gegen Einfrieren gesperrt -> kein Bricken moeglich.
- Jede Aenderung: manuelle Auswahl + Bestaetigung, protokolliert in
  `99_REPORTS_LOGS\eingefroren.txt`.
- Kein Loeschen, keine Aenderung der Headset-Aufloesung.
