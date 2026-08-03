# System Architecture Setup

Zero-friction Cloud-first Setup.
Reihenfolge strikt einhalten.

## Flow

```
Telegram -> VPS (Node.js Bot) -> KI (OpenAI/Claude) -> Notion -> Telegram
```

## Struktur

```
01-pc/           Windows + Brave Konfiguration (lokal, 1x)
02-server/       Ubuntu VPS Base + Docker + Node + Firewall
03-bot/          Telegram Bot (Node.js, dockerized)
04-integration/  OpenAI + Claude + Notion Module
05-vr/           PICO 4 Ultra Geraete-Checkliste (Cloud-Client, kein Backend-Change)
```

## Reihenfolge

1. `01-pc/brave-setup.ps1`     (Windows, als Admin)
2. `02-server/01-base.sh`      (VPS als root)
3. `02-server/02-docker.sh`    (VPS als root)
4. `02-server/03-hardening.sh` (VPS als root)
5. `03-bot/deploy.sh`          (VPS als root, nach Secrets in `.env`)

Alle Scripts sind idempotent: mehrfach ausfuehrbar, Ergebnis gleich.

**Abkuerzung:** `03-bot/SETUP_BOT_WIZARD.sh` zieht Schritte 2-5 automatisch
durch und haelt nur bei der SSH-Haertung (Aussperr-Risiko) und den
Zugangsdaten (Tokens/Keys) an. Am Ende: Erreichbarkeits-Test des Bots.

## Secrets

Nie committen. Werden nur lokal in `03-bot/.env` gesetzt.
Vorlage: `03-bot/.env.example`.
