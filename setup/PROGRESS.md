# PROGRESS

Live-Tracker. Bei jedem Schritt nach Erledigung Haken setzen.

## Inhalt

1. [Was du JETZT tust](#was-du-jetzt-tust)
2. [Erledigt](#erledigt)
3. [Spaeter / Optional](#spaeter--optional)
4. [Commit-Historie](#commit-historie)

---

## Was du JETZT tust

Single-Page-Walkthrough: [`QUICKSTART.md`](QUICKSTART.md).

### Block 1 — Notion vorbereiten
- [x] Tasks-DB um Properties **GTaskId** (Text) und **EventId** (Text) erweitert
- [ ] DB **Memory** (Name, Summary, Tags) → ID notiert
- [ ] DB **Tasks** (Name, Due, Priority, Notes, GTaskId, EventId) → ID notiert
- [ ] DB **Costs** (Name, Amount, Currency, Category, Notes) → ID notiert
- [ ] Integration **ZF** angelegt, Token notiert
- [ ] Alle 3 DBs mit ZF-Integration verbunden ("Connections")

### Block 2 — Google OAuth
Anleitung: [`4-integration/google-oauth-howto.md`](4-integration/google-oauth-howto.md)
- [ ] Google Cloud Console: Projekt `zf` + Tasks-API + Calendar-API aktiviert
- [ ] OAuth Consent Screen: External + Publish App
- [ ] OAuth Client (Desktop App) angelegt → Client-ID + Secret notiert
- [ ] Lokal: `node setup/4-integration/oauth-helper.mjs` → ENV-Block geparkt

### Block 3 — Cloudflare
- [ ] Domain in Cloudflare gehostet
- [ ] Email Routing aktiviert (DNS-Records automatisch)
- [ ] Tunnel angelegt, Token notiert, Public Hostname `bot.deine-domain` → `http://bot:8080`

### Block 4 — Cloudflare Worker
Anleitung: [`4-integration/gmail-filter.md`](4-integration/gmail-filter.md)
- [ ] `wrangler init zf-mail`, Code aus `cloudflare-worker.js` rein
- [ ] `wrangler secret put WEBHOOK_SECRET` (gleicher Wert wie `.env`)
- [ ] `wrangler secret put BOT_URL` (`https://bot.deine-domain`)
- [ ] `wrangler deploy`
- [ ] Email Routing Rule `inbox@deine-domain` → Worker `zf-mail`

### Block 5 — VPS
- [ ] VPS bestellt, IP notiert: `___.___.___.___`
- [ ] SSH-Pubkey in GitHub eingetragen
- [ ] `ssh ops@<ip>` geht ohne Passwort
- [ ] `APP_USER=ops bash setup/2-server/bootstrap.sh` durchgelaufen
- [ ] `.env` ausgefuellt (alle Keys aus den Bloecken oben + `WEBHOOK_SECRET=$(openssl rand -hex 32)`)
- [ ] `APP_USER=ops bash setup/2-server/update.sh`
- [ ] `APP_USER=ops bash setup/2-server/06-tunnel.sh`
- [ ] `APP_USER=ops bash setup/2-server/install-watchdog.sh`
- [ ] `APP_USER=ops bash setup/2-server/doctor.sh` → alles gruen

### Block 6 — Telegram
- [ ] BotFather → `/newbot` → Token in `.env`
- [ ] `@userinfobot` → User-ID in `.env` als `TELEGRAM_ALLOWED_USER_IDS`
- [ ] BotFather `/setcommands` (optional, aber huebsch)

### Block 7 — Gmail
- [ ] Forward an `inbox@deine-domain` adden, CF-Bestaetigung klicken
- [ ] Filter `subject:[ZF]` → Label `ZF` + Forward + Skip Inbox

### Block 8 — Tests
- [ ] Telegram `/start` → Antwort
- [ ] `/status` → uptime/Notion/Google/Webhook alles ok
- [ ] `/task Termin morgen 14 Uhr` → Notion + Google Tasks + Calendar
- [ ] `/cost Bahnticket 49 EUR` → Notion Costs
- [ ] Mail mit `[ZF] Test` schicken → ~30s spaeter Notion-Eintrag
- [ ] `docker logs -f zf-bot` zeigt `[mail] kind=…`

### Block 9 — PC (parallel zu allem oberhalb erledigbar)
- [x] `setup/1-pc/setup-brave.ps1` ausgefuehrt
- [ ] `setup/1-pc/style-windows.ps1` ausgefuehrt
- [ ] `setup/1-pc/links-newtab.ps1` ausgefuehrt
- [ ] `setup/1-pc/dev-setup.ps1` ausgefuehrt
- [ ] `gh auth login`
- [ ] `bw login`
- [ ] `claude` eingeloggt
- [ ] `codex` eingeloggt

---

## Erledigt

### Setup-Code (alle in PR #1)
- [x] Phase 1 — Telegram → AI → Notion-Stack (Basis)
- [x] Phase 2 — Mail-Ingest (CF Worker → Bot), Google Tasks/Calendar Sync, Cloudflare Tunnel
- [x] Phase 3 — Watchdog, Cost-Limits-Howto, QUICKSTART, MIGRATION, README/PROGRESS final

### Cheatsheet + Doku
- [x] `setup/cheatsheet.md` aus Wallpaper-Cards gefuellt + Tutorial-Sektionen (Ollama, VS Code)
- [x] `setup/RISIKEN.md` (11 Kapitel)
- [x] `setup/CLAUDE.md` (Projektregeln)

---

## Spaeter / Optional

- [ ] PR #1 mergen (Base ist auf `master`)
- [ ] Migration zu eigenem Repo `gsgjdhfafa/zf-setup` — siehe [`MIGRATION.md`](MIGRATION.md)
- [ ] Cost-Limits aktiviert — siehe [`4-integration/cost-limits.md`](4-integration/cost-limits.md)
- [ ] Multi-Desktop Setup (Win+Strg+D)
- [ ] Asana mit Bot verbinden (Phase 4 Material)

---

## Commit-Historie

- `f217e24` Basis-Stack
- `b34dbdc` Style-Skript + Cheatsheet
- `a23f8cb` Links/Default-Browser
- `b58d11f` Codex-Review-Fixes (SSH-Lockout, Compose, Cost)
- `17b2c63` Bootstrap One-Liner + update.sh
- `9076c67` /help /status + doctor.sh
- `1d40128` dev-setup + dev-tools.md + PROGRESS.md
- `8d3027f` fix-keyboard.ps1 (kann weg, brauchst du nicht)
- `006f6b2` Cheatsheet aus Wallpaper-Cards
- `d6c7be4` Cheatsheet rewrite (Deutsch, Account-Labels, Ollama, VS Code)
- `73c2289` Cheatsheet: Pipeline-Flussdiagramm + Reddit/GitHub-Tipps
- `b9a44e4` Brave/Comet/Asana + Ollama/VS-Code Use-Cases + google-oauth-howto
- `26aef5a` RISIKEN.md + README-Erweiterung
- `50becb2` CLAUDE.md (Projektregeln)
- `<next>`  Phase 3: Watchdog, Cost-Limits, QUICKSTART, MIGRATION, README final
