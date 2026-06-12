# Zero-Friction Cloud Stack

```
Telegram   ─┐
            │
Gmail [ZF] ─┴─> CF Worker ─> VPS bot ─> AI ─> Notion ─┬─> Google Tasks
                                                      └─> Google Calendar
```

Alles idempotent. Alles per Skript. Eine Domain, ein VPS (~4 €/Monat), Free-Tier-Konten sonst.

## Inhalt

1. [Quickstart](#quickstart)
2. [Datei-Layout](#datei-layout)
3. [Bot-Commands](#bot-commands)
4. [Wenn was kaputt ist](#wenn-was-kaputt-ist)
5. [Wartung](#wartung)

## Quickstart

Single-Page-Walkthrough: [`QUICKSTART.md`](QUICKSTART.md). 30 min von 0 zu lauffaehigem System.

Live-Tracker: [`PROGRESS.md`](PROGRESS.md). Da hakst du beim Setup ab.

## Datei-Layout

```
setup/
├── QUICKSTART.md          Tag-1-Walkthrough
├── PROGRESS.md            Live-Tracker (was offen, was erledigt)
├── README.md              dieses Dokument
├── CLAUDE.md              Projektregeln (Kapitel-Pflicht etc.)
├── RISIKEN.md             11 Kapitel: Secrets, Fristen, GDPR, AI-Vertrauen, …
├── MIGRATION.md           Plan: Repo-Umzug zu gsgjdhfafa/zf-setup (mittelfristig)
├── cheatsheet.md          Hotkeys, Pfade, Workflows, Ollama, VS Code, Reddit/GitHub-Tipps
│
├── 1-pc/                  Windows-PowerShell-Skripte
│   ├── run-all.ps1        One-Liner (verkettet alles)
│   ├── setup-brave.ps1    Brave + Bitwarden + Bookmarks + Start-Tabs
│   ├── style-windows.ps1  Dark Mode, Akzent, Explorer, Wallpaper
│   ├── links-newtab.ps1   Default-Browser + Tab-Verhalten
│   ├── dev-setup.ps1      Claude Code, Codex, gh, Node, VS Code, …
│   └── fix-keyboard.ps1   (legacy, nicht mehr genutzt)
│
├── 2-server/              Ubuntu-VPS-Skripte (idempotent)
│   ├── bootstrap.sh       One-Liner verkettet 01..07
│   ├── 01-base.sh         User + SSH-Keys + Pakete
│   ├── 02-security.sh     SSH haerten + UFW + fail2ban (Lockout-Schutz)
│   ├── 03-docker.sh       Docker + Compose
│   ├── 04-node.sh         Node 20 LTS + Git
│   ├── 05-deploy.sh       Repo klonen + compose up
│   ├── 06-tunnel.sh       Cloudflare Tunnel als Compose-Service
│   ├── install-watchdog.sh Cron-Eintrag fuer Watchdog (idempotent)
│   ├── watchdog.sh        Pingt /healthz, schickt Telegram-Alert
│   ├── update.sh          git pull + docker compose up -d --build
│   └── doctor.sh          Health-Check (system, security, app, container, webhook, tunnel, google, provider, watchdog)
│
├── 3-bot/                 Telegram-Bot (Node.js, Docker)
│   ├── docker-compose.yml bot + tunnel + healthcheck
│   ├── Dockerfile         node:20-alpine
│   ├── package.json       Dependencies: telegram-bot-api, undici (mehr nicht)
│   ├── .env.example       Template
│   └── src/
│       ├── index.js       Bootstrap, signal-handler
│       ├── config.js      ENV laden + validieren
│       ├── ai.js          aiStructure + aiClassify (OpenAI | Claude)
│       ├── notion.js      createPage, updatePage, T-helpers, save{Note,Task,Cost}
│       ├── google.js      Lazy OAuth2, insertTask, insertEvent
│       ├── pipeline.js    structure → save → google → backfill
│       ├── classifier.js  classify + route fuer Mail
│       ├── mail.js        CF-Worker-Payload parsen
│       ├── server.js      HTTP /mail (HMAC) + /healthz
│       └── bot.js         Telegram-Polling + Commands
│
└── 4-integration/         Externe Setups (Doku + Helfer)
    ├── flow.md                End-to-End-Flow
    ├── notion-schema.md       DB-Properties
    ├── telegram-setup.md      BotFather + User-ID
    ├── google-oauth-howto.md  Schritt-fuer-Schritt Google OAuth
    ├── oauth-helper.mjs       Lokales CLI fuer Refresh-Token
    ├── cloudflare-worker.js   Email Worker Source
    ├── gmail-filter.md        Filter + Forwarding
    ├── cost-limits.md         OpenAI/Anthropic Spend-Limits
    └── dev-tools.md           Liste der CLI-Tools nach dev-setup.ps1
```

## Bot-Commands

```
/task <text>   Aufgabe -> Notion: Tasks  (+ Google Tasks; mit Datum + Calendar-Event)
/note <text>   Notiz   -> Notion: Memory
/cost <text>   Ausgabe -> Notion: Costs
/status        uptime, AI-Provider, Notion-Ping, Google-Token, Webhook-Status
/help          Command-Liste
```

Mail-Ingest: jede Mail mit Subject `[ZF]` (oder beliebigem Filter) wird per Cloudflare Email Routing → Worker → Bot durchgereicht, AI klassifiziert kind ∈ {note, task, cost, calendar} und routet wie der entsprechende Telegram-Command.

## Wenn was kaputt ist

| Symptom                            | Erste Anlaufstelle                                  |
|------------------------------------|-----------------------------------------------------|
| Bot reagiert nicht in Telegram     | `APP_USER=ops bash setup/2-server/doctor.sh`        |
| Mails kommen nicht an              | `docker logs zf-tunnel`, dann `wrangler tail zf-mail` |
| Telegram `/status` zeigt google: fail | `node setup/4-integration/oauth-helper.mjs` neu laufen |
| Token leakt / Verdacht auf Hack    | [`RISIKEN.md`](RISIKEN.md) Kapitel 1                |
| Sache unklar                       | [`cheatsheet.md`](cheatsheet.md), oder Sektion in `4-integration/` |

## Wartung

- **Woechentlich**: Telegram `/status`. Wenn alles `ok` → ignorieren.
- **Monatlich**: `update.sh` auf VPS (zieht Container-Updates + Code-Stand).
- **Quartalsweise**: `docker system prune -f`, Notion-Export herunterladen.
- **Watchdog**: laeuft per Cron alle 5 min, schickt Telegram-Alert wenn Bot 3x in Folge nicht antwortet. Pflegt sich selbst.
