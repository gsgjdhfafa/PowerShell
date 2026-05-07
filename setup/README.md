# Zero-Friction Cloud Stack

```
Telegram  ->  VPS  ->  KI (OpenAI/Claude)  ->  Notion  ->  Telegram
```

## Reihenfolge

1. `1-pc/`          Windows Brave + Bookmarks + Start-Tabs + Style
2. `2-server/`      Ubuntu VPS: Base, Security, Docker, Node
3. `3-bot/`         Telegram Bot (Node.js, Docker)
4. `4-integration/` Notion DBs + ENV Template
5. `cheatsheet.md`  Shortcuts (wird aus Screenshots gepflegt)

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
