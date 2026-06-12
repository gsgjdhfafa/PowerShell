# Migration zu eigenem Repo

Aktuell liegt `setup/` im Fork `gsgjdhfafa/PowerShell` (200 MB Microsoft-Code drumrum). Mittelfristig gehoert das in ein eigenes Repo `gsgjdhfafa/zf-setup` mit ~150 KB.

Dieses Dokument ist die Anleitung dafuer. **Nicht jetzt zwingend noetig** — aktueller Stand laeuft.

## Inhalt

1. [Wann lohnt sich der Umzug](#1-wann-lohnt-sich-der-umzug)
2. [Vorbereitung](#2-vorbereitung)
3. [Repo herausschneiden](#3-repo-herausschneiden)
4. [Neues Repo pushen](#4-neues-repo-pushen)
5. [VPS umstellen](#5-vps-umstellen)
6. [Aufraeumen](#6-aufraeumen)

## 1. Wann lohnt sich der Umzug

- Du willst den Branch nicht laenger gegen den 200-MB-PowerShell-Fork halten.
- Du willst eigene CI auf der `setup/`-Pipeline (Lint, Tests).
- Du willst andere Personen einladen (sonst sehen die alle PowerShell-Internals).
- Du willst die Commit-Historie auf `setup/`-Aenderungen reduziert haben.

## 2. Vorbereitung

```powershell
# Lokaler Clone des aktuellen Stands
git clone https://github.com/gsgjdhfafa/PowerShell.git zf-setup-temp
cd zf-setup-temp
git checkout claude/setup-system-architecture-DvgRI
```

`git filter-repo` installieren (einmalig):
```powershell
winget install Astral.Uv
uvx git-filter-repo --version   # Test
```
Alternativ: `pip install git-filter-repo`.

## 3. Repo herausschneiden

```bash
# Subdirectory rausschneiden, Historie behalten, Pfade hochziehen.
uvx git-filter-repo --subdirectory-filter setup
```

Resultat: das Repo enthaelt nur noch Files, die in `setup/` waren — auf der Wurzel.
Branch heisst weiterhin `claude/setup-system-architecture-DvgRI`. Renne ihn um:
```bash
git branch -m main
```

## 4. Neues Repo pushen

GitHub:
1. https://github.com/new → Owner `gsgjdhfafa`, Name `zf-setup`, **Private**, ohne README/`.gitignore`/License → Create.

```bash
git remote remove origin
git remote add origin git@github.com:gsgjdhfafa/zf-setup.git
git push -u origin main
```

## 5. VPS umstellen

Auf dem VPS (`ops`):
```bash
cd ~/app
git remote set-url origin git@github.com:gsgjdhfafa/zf-setup.git
git fetch origin
git checkout main
git reset --hard origin/main
```

`update.sh` und `bootstrap.sh` auf das neue Layout anpassen — die Pfade `setup/3-bot/` werden zu `3-bot/`. **Wichtig**:
- In `update.sh`: `cd setup/3-bot` → `cd 3-bot`.
- In `bootstrap.sh`: `$SD/01-base.sh` etc. bleibt (Pfade sind relativ zum Skript-Verzeichnis).
- In `06-tunnel.sh` und `install-watchdog.sh`: hardcoded `app/setup/3-bot/.env` → `app/3-bot/.env`.
- In `watchdog.sh`: `ENV_FILE` Pfad anpassen.
- Doctor-`env_file`-Pfad anpassen.

Diese Anpassungen **vor** dem Umzug machen, sonst bricht das System.

## 6. Aufraeumen

- PR #1 in `gsgjdhfafa/PowerShell` schliessen mit Hinweis: „Migrated to gsgjdhfafa/zf-setup".
- Branch `claude/setup-system-architecture-DvgRI` im PowerShell-Fork loeschen.
- Lokale Clones: alten `PowerShell/`-Ordner loeschen, neu `zf-setup` clonen.
- Bookmarks aktualisieren.

## Risiko / Wenn du es zurueckdrehen willst

`git filter-repo` ist destruktiv (es schreibt Hashes neu). **Loeschst du das alte Repo nicht**, kannst du jederzeit zurueck. Empfehlung: PowerShell-Fork mindestens 2 Wochen nach Migration stehen lassen.
