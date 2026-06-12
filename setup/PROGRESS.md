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

### Block 10 — WSL + AI-Agents (Hermes, OpenCode)
- [ ] Admin-PowerShell: `setup/1-pc/install-wsl.ps1`
- [ ] **Reboot** durchgelaufen
- [ ] Ubuntu erstmalig gestartet (User + Passwort vergeben)
- [ ] In Ubuntu: `bash setup/1-pc/install-agents-in-wsl.sh`
- [ ] `claude /login` in WSL
- [ ] `ollama launch hermes` in WSL

### Block 11 — Chat-Apps + OpenClaw auf dem PC
- [ ] `setup/1-pc/install-chat-apps.ps1` ausgefuehrt
- [ ] Telegram Desktop: mit Telefonnummer + SMS-Code eingeloggt
- [ ] WhatsApp Desktop: per QR-Code mit Handy verknuepft
- [ ] `ollama launch openclaw` durchgelaufen, OpenClaw startet

### Block 12 — ZF Global Hotkeys (Phase 4 + Phase 5)
Installer: `setup/1-pc/install-hotkeys.ps1` (nicht-elevated, idempotent).
Ablage-Ordner: `C:\Users\Admin\Documents\SOT_MASTER_LIVE`.
- [ ] `setup/1-pc/install-hotkeys.ps1` ausgefuehrt (AHK v2 via winget + Startup-Shortcut, kopiert auch `extract-content.ps1` + `hover-explain.ps1`)
- [ ] Tray zeigt gruenes H (AHK laeuft)
- [ ] `Alt+Ctrl+F` -> Everything geht auf
- [ ] `Alt+Ctrl+G` -> 4 Explorer-Fenster fuer Aufgabenbereiche
- [ ] `Alt+Ctrl+S` -> Datei landet in `SOT_MASTER_LIVE`
- [ ] `Alt+Ctrl+X` -> Duplikate wandern nach `_Versions\<timestamp>\`
- [ ] `Alt+Ctrl+A` mit PDF/DOCX/XLSX selektiert -> Text im Clipboard
- [ ] `Alt+Ctrl+Y` -> Tray-Balloon mit Ollama-Erklaerung (oder Google-Fallback)
- [ ] `Ctrl+^` (bzw. `Ctrl+F12`) -> Fenster werden gekachelt
- [ ] Reboot -> AHK startet automatisch (Startup-Shortcut)

Hover-Explain ENV (optional, fuer `Alt+Ctrl+Y`):
- `ZF_OLLAMA_URL`   (Default `http://localhost:11434`)
- `ZF_OLLAMA_MODEL` (Default `llama3.2:3b`)
In PowerShell setzen: `setx ZF_OLLAMA_MODEL "hermes3:8b"` (neue Shell zum Aktivieren).

Hotkey-Mapping (Kurz):

| Chord | Aktion |
|-------|--------|
| `Alt+Ctrl+Q` / `F` | Everything oeffnen |
| `Alt+Ctrl+W` | InputBox-Pattern -> Everything |
| `Alt+Ctrl+E` | Explorer: Dateien der letzten Stunde |
| `Alt+Ctrl+A` | Inhalt der Explorer-Selektion in Clipboard (Text-Dateien) |
| `Alt+Ctrl+S` | Selektion -> `SOT_MASTER_LIVE` kopieren + Ordner oeffnen |
| `Alt+Ctrl+D` | Windows Power-Panel |
| `Alt+Ctrl+G` | 4 Explorer mit Pitch/Bewerbung/Insolvenz/Betreuung |
| `Alt+Ctrl+Y` | Tooltip mit Fenster-Info + Google-Suche |
| `Alt+Ctrl+X` | Duplikate -> `_Versions\<timestamp>\` |
| `Alt+Ctrl+P` | Snipping-Tool (`Win+Shift+S`) |
| `Alt+Ctrl+V` | Xbox Game Bar Aufnahme (`Win+Alt+R`) |
| `Alt+Ctrl+B` | Global Undo (`Ctrl+Z`) |
| `Ctrl+^` / `Ctrl+F12` | Alle Fenster ueber Monitore kacheln |

Grenzen:
- `Alt+Ctrl+A` nur Text (`.txt/.md/.json/.ps1/...`). Binaer-Extraktion (PDF/DOCX) folgt in Phase 5.
- `Alt+Ctrl+S` kopiert (Goldene Regel: Originale nie verschieben).
- `Alt+Ctrl+B` ist `Ctrl+Z` an die aktive App — keine app-uebergreifende History.
- `Alt+Ctrl+D` oeffnet nur das Panel, killt keine Hintergrund-Tasks.
- KI-Hover (`Alt+Ctrl+Y`) ist aktuell Google-Suche — Ollama-Anbindung folgt in Phase 5.

---

## Erledigt

### Setup-Code (alle in PR #1)
- [x] Phase 1 — Telegram → AI → Notion-Stack (Basis)
- [x] Phase 2 — Mail-Ingest (CF Worker → Bot), Google Tasks/Calendar Sync, Cloudflare Tunnel
- [x] Phase 3 — Watchdog, Cost-Limits-Howto, QUICKSTART, MIGRATION, README/PROGRESS final
- [x] Phase 4 — ZF Global Hotkeys (AHK v2, Installer, Dedup-Helper)
- [x] Phase 5 — Content-Extractor (PDF/DOCX/XLSX/PPTX) + Ollama-Hover-Explain

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
- [ ] Asana mit Bot verbinden

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
- `ca4980b` Phase 3: Watchdog, Cost-Limits, QUICKSTART, MIGRATION, README/PROGRESS final
- `3d9f83a` WSL2 + AI-Agents Installer
- `e8358de` install-chat-apps.ps1 (Telegram, WhatsApp, OpenClaw)
- `595f70b` kickstart.ps1 (one-shot PC bootstrap)
- `45f3c32` zf-all.ps1 (single-script Windows bootstrap)
- `6d11d43` analyze.ps1 (read-only Inventory)
- `d299929` Phase 4: ZF Global Hotkeys (AHK v2 + Installer + Dedup-Helper)
- `f008127` Fix: dedup-Pipeline-Scope + MessageBox-Lade-Reihenfolge + AHK Windows()
- `<next>`  Phase 5: extract-content.ps1 (PDF/DOCX/XLSX/PPTX) + hover-explain.ps1 (Ollama)
