# Bot Deploy — Links & Zugangsdaten (Checkliste)

Vor `SETUP_BOT_WIZARD.sh` (oder manuellem Ausfuellen von `.env`) diese
Punkte einmal durchgehen. Dauert ~10 Minuten, danach hat der Wizard
alles, was er fuer den automatischen Durchlauf braucht.

## 1. Telegram Bot Token
- https://t.me/BotFather → `/newbot` → Namen vergeben
- Ergebnis: `TELEGRAM_BOT_TOKEN` (Format: `123456:ABC-...`)

## 2. Telegram User-ID (nur du darfst den Bot nutzen)
- https://t.me/userinfobot → `/start` → zeigt deine ID
- Ergebnis: `TELEGRAM_ALLOWED_USER_ID` (nur Zahl)

## 3. Notion Integration (Zugriffs-Token)
- https://www.notion.so/my-integrations → "+ New integration"
- Ergebnis: `NOTION_TOKEN` (Format: `secret_...` oder `ntn_...`)

## 4. Notion-Datenbanken (3x anlegen, mit der Integration teilen)
In jeder DB: "..." (oben rechts) → "Connections" → deine Integration
hinzufuegen. Die DB-ID steht im Link: `notion.so/<workspace>/<DB-ID>?v=...`

| Datenbank | Pflicht-Properties | Env-Var |
|---|---|---|
| Memory | Title (title), Tags (multi_select), Content (rich_text) | `NOTION_DB_MEMORY` |
| Tasks  | Title (title), Status (status, Default "Todo"), Tags (multi_select) | `NOTION_DB_TASKS` |
| Costs  | Title (title), Amount (number, EUR), Tags (multi_select) | `NOTION_DB_COSTS` |

## 5. Anthropic (Claude — primaer)
- https://console.anthropic.com/settings/keys → "Create Key"
- Ergebnis: `ANTHROPIC_API_KEY`

## 6. OpenAI (Fallback, optional aber empfohlen)
- https://platform.openai.com/api-keys → "Create new secret key"
- Ergebnis: `OPENAI_API_KEY`

## 7. VPS-Zugang
IP-Adresse + SSH-Key-Zugang als root (oder sudo-faehiger User).

## 8. Deploy starten
Auf dem VPS, im geklonten Repo:

```bash
sudo bash setup-system-architecture/03-bot/SETUP_BOT_WIZARD.sh
```

Fragt automatisch genau die Werte aus Punkt 1–6 ab, alles andere
(System-Basis, Docker, Haertung, Deploy, Erreichbarkeitstest) laeuft
automatisch durch. Danach: `/start` an den Bot in Telegram senden —
Antwort "ready. /task /note /cost oder freier Text." bestaetigt, dass
alles funktioniert.

## Nichts zur Hand?
`.env.example` in diesem Ordner zeigt alle Variablen mit Defaults.
`.env` wird nie committed (`.gitignore`).
