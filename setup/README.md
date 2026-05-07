# Zero-Friction Cloud Stack

```
Telegram  ->  VPS  ->  KI (OpenAI/Claude)  ->  Notion  ->  Telegram
```

## Reihenfolge

1. `1-pc/`          Windows Brave + Bookmarks + Start-Tabs + Style + Dev-Toolchain
2. `2-server/`      Ubuntu VPS: Base, Security, Docker, Node
3. `3-bot/`         Telegram Bot (Node.js, Docker)
4. `4-integration/` Notion DBs + ENV Template + Dev-Tools-Liste
5. `cheatsheet.md`  Shortcuts (wird aus Screenshots gepflegt)
6. `PROGRESS.md`    Live-Tracker, Haken setzen waehrend Setup laeuft

Jeder Schritt ist idempotent. Mehrfach ausfuehrbar. Keine GUI.

## PC-Skripte

One-Liner (alles auf einmal):
```
powershell -ExecutionPolicy Bypass -File setup/1-pc/run-all.ps1
# Optionen:
#   -Mode Dark|Light
#   -AccentHex '#7B61FF'
#   -Wallpaper 'C:\Users\<du>\Pictures\wall.jpg'
```

Einzeln:
```
powershell -ExecutionPolicy Bypass -File setup/1-pc/setup-brave.ps1
powershell -ExecutionPolicy Bypass -File setup/1-pc/style-windows.ps1
powershell -ExecutionPolicy Bypass -File setup/1-pc/links-newtab.ps1
```

## Server-Skripte

One-Liner (als root):
```
APP_USER=ops bash setup/2-server/bootstrap.sh
# Mit Deploy:
APP_USER=ops REPO_URL=git@github.com:<u>/<r>.git BRANCH=main \
    bash setup/2-server/bootstrap.sh
```

Bot updaten (spaeter):
```
APP_USER=ops BRANCH=main bash setup/2-server/update.sh
```

Health-Check:
```
APP_USER=ops bash setup/2-server/doctor.sh
```

## Bot Commands

```
/task <text>   Aufgabe -> Notion: Tasks
/note <text>   Notiz   -> Notion: Memory
/cost <text>   Ausgabe -> Notion: Costs
/status        Bot-Health (uptime, AI provider, Notion-Ping)
/help          Command-Liste
```
