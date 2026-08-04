# PICO 4 Ultra — was du jetzt tun kannst (Stand 04.08.2026)

## Sofort nutzbar

**Voice → Notion (der Haupt-Use-Case):**
Telegram in der Brille öffnen → Mikro-Button drücken → sprechen →
landet strukturiert in Notion (Memory/Tasks/Costs, je nach Inhalt).
Funktioniert auch mit `/task`, `/note`, `/cost` + Text.

**Bildschirm am Mac live sehen (scrcpy):**
```bash
scrcpy --crop 2160:2160:0:0   # nur ein Auge, empfohlen
```
(scrcpy vorher installieren: `brew install scrcpy`)

**Multi-Monitor (virtuelle Bildschirme im Raum):**
```bash
bash ~/Desktop/PICO_CONNECT_MAC.command
```
Danach in der App: Brille verbinden, virtuelle Monitore einrichten.

**Umgebung scannen (Wände/Boden, Objekte funktionalisieren):**
```bash
bash ~/Desktop/PICO_SPACE_SETUP.command
```
Öffnet die Settings in der Brille, Rest läuft im Headset (Kamera-Tracking).

## Laufende Pflege

**Regelmäßig prüfen, was neu dazugekommen ist:**
```bash
bash ~/Desktop/PICO_AUDIT_MAC.command
```
Zeigt: Ziel-Apps vorhanden/fehlend, neue Kandidaten zum Einfrieren,
was schon eingefroren ist.

**Weitere Apps einfrieren/auftauen (interaktiv, mit Sicherheitsabfrage):**
```bash
curl -fsSL -o ~/Desktop/PICO_CONTROL_CENTER.py "https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-XKISu/setup-system-architecture/05-vr/pico-control-center/PICO_CONTROL_CENTER.py" && python3 ~/Desktop/PICO_CONTROL_CENTER.py
```
Punkt 12 = einfrieren, Punkt 13 = auftauen (jederzeit rückgängig).

**Nach Werksreset / Neuaufsetzen — alles in einem Rutsch wiederherstellen:**
```bash
bash ~/Desktop/PICO_REBUILD_ALL.command
```
Installiert die 4 Ziel-Apps, friert die 13 bestätigten Apps wieder ein,
öffnet die Login-Seiten. Ersetzt praktisch den kompletten heutigen Chat.

## Was bewusst NICHT automatisiert ist

- Objekt-Anker (z.B. Papierkorb funktionalisieren) — nur im Headset, Kamera-Tracking.
- PICO-Connect-Feineinstellungen (Bitrate, Auflösung) — nur über die App-GUI,
  kein dokumentiertes Terminal-Interface.
- Bot-Betrieb selbst — läuft auf deinem VPS, nicht auf der Brille
  (siehe `03-bot/SETUP_BOT_WIZARD.sh` + `03-bot/DEPLOY_LINKS.md`).

## Alle Skripte im Überblick

| Datei | Zweck |
|---|---|
| `pico-control-center/PICO_MAC.command` | Ziel-Apps installieren (einzeln) |
| `pico-control-center/PICO_AUDIT_MAC.command` | Status-Scan: da / fehlt / Kandidat |
| `pico-control-center/PICO_FREEZE_BATCH*.command` | Bestätigte Kandidaten einfrieren |
| `pico-control-center/PICO_SPACE_SETUP.command` | Umgebungsaufzeichnung starten |
| `pico-control-center/PICO_CONTROL_CENTER.py` | Vollmenü (Python, alle Funktionen) |
| `pico-rebuild/PICO_REBUILD_ALL.command` | Alles auf einmal, nach Reset |
| `pico-rebuild/PICO_CONNECT_MAC.command` | PICO Connect starten (Multi-Monitor) |
