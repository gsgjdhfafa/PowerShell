# Quickstart — von 0 zu lauffaehigem System (~30 min)

Single-Page-Walkthrough. Jeder Punkt verlinkt zur Detail-Doku, **hier nur die Reihenfolge**.

## Inhalt

1. [Vorbereitung](#1-vorbereitung)
2. [PC setup](#2-pc-setup)
3. [VPS bestellen + bootstrap](#3-vps-bestellen--bootstrap)
4. [Notion vorbereiten](#4-notion-vorbereiten)
5. [Telegram-Bot anlegen](#5-telegram-bot-anlegen)
6. [Google OAuth](#6-google-oauth)
7. [Cloudflare Tunnel + Email Routing + Worker](#7-cloudflare-tunnel--email-routing--worker)
8. [Gmail-Filter](#8-gmail-filter)
9. [Bot starten + verifizieren](#9-bot-starten--verifizieren)
10. [Tests](#10-tests)

---

## 1. Vorbereitung

Du brauchst:
- GitHub-Account (`gh`)
- Bitwarden (oder anderer Passwort-Manager)
- Eine Domain auf Cloudflare gehostet
- Hetzner / Dogado / anderer VPS-Anbieter
- Google-Account (Gmail + Calendar)
- Telegram-Account

Optional: Notion (Free reicht), Asana (Free reicht), OpenAI **oder** Anthropic API.

---

## 2. PC setup

```powershell
gh repo clone gsgjdhfafa/PowerShell
cd PowerShell
git checkout claude/setup-system-architecture-DvgRI

powershell -ExecutionPolicy Bypass -File setup\1-pc\run-all.ps1 `
    -GitName 'Vorname Nachname' -GitEmail 'du@example.com'
```

Was passiert: Brave + Bitwarden + Style + Default-Browser + Dev-Toolchain (Claude Code, Codex, gh, Node, etc.).

Nach dem Lauf: SSH-Pubkey notieren (steht im Output), `gh auth login`, `bw login`, `claude` (`/login`), `codex`.

Details: [`setup/cheatsheet.md`](cheatsheet.md), [`setup/1-pc/`](1-pc/)

---

## 3. VPS bestellen + bootstrap

1. Hetzner Cloud Console → Server bestellen → CX22 (4 €/Monat) reicht.
2. SSH-Key (aus Schritt 2) bei Bestellung eintragen.
3. IP notieren.

Auf dem PC:
```powershell
ssh-copy-id ops@<ip>     # falls noetig — bei Hetzner-Key-Setup automatisch
ssh root@<ip>            # ins frische System
```

Auf dem VPS (als root):
```bash
git clone https://github.com/gsgjdhfafa/PowerShell.git app
cd app && git checkout claude/setup-system-architecture-DvgRI
APP_USER=ops bash setup/2-server/bootstrap.sh
```

Bootstrap macht: User anlegen, SSH haerten (Lockout-Schutz drin), Docker, Node, Tunnel- und Watchdog-Hooks (greifen automatisch sobald `.env` da ist).

Details: [`setup/2-server/`](2-server/), [`setup/RISIKEN.md`](RISIKEN.md)

---

## 4. Notion vorbereiten

1. Workspace anlegen.
2. Drei Datenbanken (full-page) anlegen: `Memory`, `Tasks`, `Costs`.
3. Properties **exakt** wie in [`notion-schema.md`](4-integration/notion-schema.md). Tasks-DB braucht zusaetzlich `GTaskId` (Text) + `EventId` (Text).
4. Notion → Settings → Connections → Integration **ZF** anlegen, Token kopieren.
5. Jede DB: `…` → **Connections** → ZF hinzufuegen.

Du brauchst am Ende: `NOTION_TOKEN` + 3 DB-IDs (32-Zeichen-Hex aus jeder DB-URL).

---

## 5. Telegram-Bot anlegen

1. Telegram → `@BotFather` → `/newbot` → Token notieren.
2. Telegram → `@userinfobot` → eigene numerische ID notieren.
3. Optional: BotFather `/setcommands`:
   ```
   task - Aufgabe anlegen
   note - Notiz speichern
   cost - Ausgabe erfassen
   status - Bot-Status
   help - Befehle
   ```

Details: [`setup/4-integration/telegram-setup.md`](4-integration/telegram-setup.md)

---

## 6. Google OAuth

Volle Anleitung: [`google-oauth-howto.md`](4-integration/google-oauth-howto.md). Kurzform:

1. Google Cloud Console → Projekt `zf` → APIs aktivieren: Tasks + Calendar.
2. OAuth Consent Screen → External → Publish App.
3. OAuth Client ID → Desktop App → Client ID + Secret notieren.
4. Lokal:
   ```powershell
   node setup\4-integration\oauth-helper.mjs
   ```
   → druckt fertigen `.env`-Block (`GOOGLE_CLIENT_ID`, `_SECRET`, `_REFRESH_TOKEN`, `_TASKS_LIST_ID`).

---

## 7. Cloudflare Tunnel + Email Routing + Worker

1. Cloudflare Dashboard → Domain → **Email Routing** aktivieren (DNS-Records werden gesetzt).
2. Cloudflare → Zero Trust → Networks → Tunnels → **„Create a tunnel"** → Token notieren → Public Hostname `bot.deine-domain` → Service `http://bot:8080`.
3. Worker deployen:
   ```powershell
   npm i -g wrangler
   wrangler init zf-mail
   # Inhalt von setup/4-integration/cloudflare-worker.js in src/worker.js
   wrangler secret put WEBHOOK_SECRET   # gleicher Wert wie .env (gleich generieren)
   wrangler secret put BOT_URL          # https://bot.deine-domain
   wrangler deploy
   ```
4. CF Dashboard → Email Routing → Rule `inbox@deine-domain` → Action **„Send to Worker"** → `zf-mail`.

Details: [`gmail-filter.md`](4-integration/gmail-filter.md)

---

## 8. Gmail-Filter

1. Gmail → Settings → Forwarding → `inbox@deine-domain` adden, CF-Bestaetigung in Email Routing klicken.
2. Filter erstellen → Kriterium z.B. `subject:[ZF]`.
3. Aktion: Label `ZF`, Forward an `inbox@deine-domain`, optional Skip Inbox.

---

## 9. Bot starten + verifizieren

`.env` auf dem VPS ausfuellen:
```bash
ssh ops@<ip>
cd ~/app/setup/3-bot
cp .env.example .env
nano .env
```

`.env` muss enthalten:
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`
- `OPENAI_API_KEY` **oder** `ANTHROPIC_API_KEY`, `AI_PROVIDER`
- `NOTION_TOKEN`, 3 DB-IDs
- `WEBHOOK_SECRET` (frisch via `openssl rand -hex 32`)
- Google-Block (aus Schritt 6)
- `CF_TUNNEL_TOKEN`

Dann:
```bash
APP_USER=ops bash ~/app/setup/2-server/update.sh
APP_USER=ops bash ~/app/setup/2-server/06-tunnel.sh
APP_USER=ops bash ~/app/setup/2-server/install-watchdog.sh
APP_USER=ops bash ~/app/setup/2-server/doctor.sh
```

`doctor.sh` muss alles **gruen** zeigen (max ein paar `[WARN]` zu erwarten ohne aktiven Mail-Verkehr).

---

## 10. Tests

Telegram:
- `/start` → Antwort mit Command-Liste.
- `/status` → uptime, Notion ok, Google ok, Webhook on.
- `/note Test` → Notion Memory-Eintrag.
- `/task Steuern morgen 14 Uhr` → Notion Tasks + Google Tasks + Calendar Event.
- `/cost Bahnticket 49 EUR` → Notion Costs.

Mail:
- Mail mit Subject `[ZF] Bahnticket 49 EUR` an dich selbst → ~30 s spaeter Notion Costs-Eintrag.
- `docker logs -f zf-bot` zeigt `[mail] from=… kind=cost …`.

Watchdog (nur wenn du absichtlich testen willst):
- `docker stop zf-bot` → 15 min spaeter Telegram-Alert.
- `docker start zf-bot` → Recovery-Alert.

Details: [`flow.md`](4-integration/flow.md), [`gmail-filter.md`](4-integration/gmail-filter.md)
