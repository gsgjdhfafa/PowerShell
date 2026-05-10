# PROGRESS

Live-Tracker. Bei jedem Schritt nach Erledigung Haken setzen.

## Phase 1 — PC (Brave + Style + Tools)
- [x] `setup/1-pc/setup-brave.ps1` ausgefuehrt   (Brave + Bitwarden + Bookmarks + Start-Tabs)
- [ ] `setup/1-pc/style-windows.ps1` ausgefuehrt (Dark Mode, Akzent, Explorer, Wallpaper)
- [ ] `setup/1-pc/links-newtab.ps1`  ausgefuehrt (Default-Browser, Tab-Verhalten)
- [ ] `setup/1-pc/dev-setup.ps1`     ausgefuehrt (Claude Code, Codex, gh, Bitwarden, etc.)
- [ ] SSH-Pubkey in GitHub eingetragen
- [ ] `gh auth login`
- [ ] `bw login` und Vault entsperrt
- [ ] `claude` eingeloggt
- [ ] `codex` eingeloggt

## Phase 2 — VPS (Hetzner / Dogado)
- [ ] VPS bestellt, IP notiert: `___.___.___.___`
- [ ] DNS (optional) gesetzt: `___`
- [ ] `ssh-copy-id ops@<ip>` (siehe Pubkey aus dev-setup.ps1)
- [ ] `bash setup/2-server/01-base.sh`
- [ ] `bash setup/2-server/02-security.sh`
- [ ] `bash setup/2-server/03-docker.sh`
- [ ] `bash setup/2-server/04-node.sh`
- [ ] `bash setup/2-server/05-deploy.sh`
- [ ] oder One-Liner: `APP_USER=ops bash setup/2-server/bootstrap.sh`
- [ ] `bash setup/2-server/doctor.sh` -> alles gruen

## Phase 3 — Bot
- [ ] Telegram-Bot bei `@BotFather` angelegt, Token notiert
- [ ] Eigene User-ID via `@userinfobot`, in `.env` als `TELEGRAM_ALLOWED_USER_IDS`
- [ ] `OPENAI_API_KEY` ODER `ANTHROPIC_API_KEY` gesetzt
- [ ] `AI_PROVIDER` gewaehlt (`claude` | `openai`)
- [ ] Container laeuft: `docker ps | grep zf-bot`
- [ ] `/start` -> Antwort
- [ ] `/status` -> Notion: ok

## Phase 4 — Notion
- [ ] Integration "ZF" angelegt, Token in `.env` als `NOTION_TOKEN`
- [ ] DB **Memory**  (Name, Summary, Tags) -> ID in `.env`
- [ ] DB **Tasks**   (Name, Due, Priority, Notes) -> ID in `.env`
- [ ] DB **Costs**   (Name, Amount, Currency, Category, Notes) -> ID in `.env`
- [ ] alle drei DBs mit Integration verbunden ("Connections")
- [ ] Test: `/note hello` -> erscheint in Memory
- [ ] Test: `/task gemuese kaufen morgen` -> erscheint in Tasks
- [ ] Test: `/cost kaffee 3.50 EUR` -> erscheint in Costs

## Phase 5 — Habits / Cheatsheet
- [ ] Brave-Bookmarks geprueft, Start-Tabs ok
- [ ] Multi-Desktop Setup (Win+Strg+D fuer neuen Desktop)
- [x] `setup/cheatsheet.md` aus Bilder-Ordner gefuellt
- [ ] PR #1 gemerged (Base ggf. auf `main` umgestellt)

## Phase 6 — Mail-Ingest, Google Sync, Tunnel
- [ ] Cloudflare: Domain ist auf CF, **Email Routing** aktiv
- [ ] Cloudflare: **Tunnel** angelegt, Public Hostname `bot.deine-domain` -> `http://bot:8080`, Token in `.env` als `CF_TUNNEL_TOKEN`
- [ ] Google Cloud Console: Projekt + OAuth-Client "Desktop App", Consent-Screen "In production"
- [ ] `node setup/4-integration/oauth-helper.mjs` ausgefuehrt -> ENV-Block in `.env` eingetragen
- [x] Notion: Tasks-DB um Properties **GTaskId** (Text) und **EventId** (Text) erweitert
- [ ] **Block 2** Google OAuth: siehe `setup/4-integration/google-oauth-howto.md`
- [ ] `WEBHOOK_SECRET` (>= 32 Zeichen) in `.env` gesetzt
- [ ] Cloudflare Worker `zf-mail` deployed (`wrangler deploy`), Secrets `WEBHOOK_SECRET` + `BOT_URL`
- [ ] Email Routing Rule `inbox@deine-domain` -> Worker `zf-mail`
- [ ] Gmail-Filter `[ZF]` -> Forward an `inbox@deine-domain`, Forward-Adresse bestaetigt
- [ ] `bash setup/2-server/06-tunnel.sh` -> Tunnel-Container laeuft
- [ ] `curl https://bot.deine-domain/healthz` -> `{"ok":true,...}`
- [ ] Test-Mail mit `[ZF]` Subject -> Notion-Eintrag erscheint
- [ ] `/task ... morgen 14 Uhr` -> Notion + Google Tasks + Calendar Event
- [ ] `doctor.sh` zeigt tunnel + webhook + google: ok

## Commits (Historie)
- `f217e24` Basis-Stack
- `b34dbdc` Style-Skript + Cheatsheet
- `a23f8cb` Links/Default-Browser
- `b58d11f` Codex-Review-Fixes (SSH-Lockout, Compose, Cost)
- `17b2c63` Bootstrap One-Liner + update.sh
- `9076c67` /help /status + doctor.sh
- `1d40128` dev-setup + dev-tools.md + PROGRESS.md
- `<next>`  Phase 2: src/-Refactor, Mail-Ingest, Google-Sync, CF-Tunnel
