# Zero-Friction Cloud Stack

```
Telegram   ─┐
            │
Gmail [ZF] ─┴─> CF Worker ─> VPS bot ─> AI ─> Notion ─┬─> Google Tasks
                                                      └─> Google Calendar
```

## Reihenfolge

1. `1-pc/`          Windows Brave + Bookmarks + Start-Tabs + Style + Dev-Toolchain
2. `2-server/`      Ubuntu VPS: Base, Security, Docker, Node
3. `3-bot/`         Telegram Bot (Node.js, Docker)
4. `4-integration/` Notion DBs + ENV Template + Dev-Tools-Liste
5. `cheatsheet.md`  Shortcuts (wird aus Screenshots gepflegt)
6. `PROGRESS.md`    Live-Tracker, Haken setzen waehrend Setup laeuft
7. `RISIKEN.md`     was schiefgehen kann + Hygiene-Regeln
8. `CLAUDE.md`      Projekt-Regeln fuer Claude Code (Kapitel-Pflicht etc.)

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
/task <text>   Aufgabe -> Notion: Tasks  (+ Google Tasks; mit Datum + Calendar-Event)
/note <text>   Notiz   -> Notion: Memory
/cost <text>   Ausgabe -> Notion: Costs
/status        uptime, AI, Notion, Google, Webhook
/help          Command-Liste
```

## Mail-Ingest (Phase 2)

Gmail-Filter mit Label `[ZF]` -> Cloudflare Email Routing -> Worker -> Bot
`/mail`-Webhook (HMAC-signiert). AI klassifiziert (note/task/cost/calendar)
und routet wie der jeweilige Telegram-Command.

Setup:
- `setup/4-integration/oauth-helper.mjs` lokal -> Google-Refresh-Token.
- `setup/4-integration/cloudflare-worker.js` per `wrangler deploy`.
- `setup/4-integration/gmail-filter.md` als Anleitung.
- `setup/2-server/06-tunnel.sh` startet `cloudflared`-Container.
