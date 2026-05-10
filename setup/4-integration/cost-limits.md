# Cost-Limits — Klick-Anleitung

Damit dir kein Bug oder gehackter Token eine $4000-Rechnung produziert.

## Inhalt

1. [OpenAI](#1-openai)
2. [Anthropic Claude](#2-anthropic-claude)
3. [Hetzner](#3-hetzner)
4. [Cloudflare](#4-cloudflare)
5. [Notion / Asana](#5-notion--asana)

## 1. OpenAI

1. https://platform.openai.com/account/billing/limits
2. **Soft limit** (Mail-Warnung): $5 — du kriegst eine Mail wenn du ~25% des Hard-Limits erreicht hast.
3. **Hard limit** (komplett blockiert): $20.
4. Email-Notifications: AN.
5. Zusaetzlich: **Usage** Tab → woechentlich kurz reinschauen.

API-Keys einzeln rotierbar:
- https://platform.openai.com/api-keys → einzelne Keys mit Namen + Limits anlegen statt einem grossen Master-Key.

## 2. Anthropic Claude

1. https://console.anthropic.com/settings/billing
2. **Spend Limit** auf $20/Monat setzen.
3. **Email Alerts** aktivieren.
4. API-Keys: gleicher Tipp wie bei OpenAI — pro Use-Case ein Key.

## 3. Hetzner

Kein API-Cost-Limit — Hetzner bucht den Plan-Preis monatlich. Schutz:
- Cloud Console → Project → **Limits** → Server-Anzahl + Volume-Groesse hart begrenzen.
- 2FA aktivieren (Settings → Security).
- Snapshots loeschen wenn nicht mehr noetig (5€/Monat pro 100 GB).

## 4. Cloudflare

Free-Tier reicht fuer alles in Phase 2:
- Email Routing: 100k Forwards / Tag.
- Worker: 100k Requests / Tag, 10ms CPU.
- Tunnel: 50 GB / Monat outgoing.

**Schutz** (falls du irgendwann auf Pro upgrades):
- Cloudflare Dashboard → Account Home → Billing → **Spend Limit**.
- Workers KV / R2 / D1 nur einrichten wenn explizit gewollt — Free-Limits sind grosszuegig aber nicht null.

## 5. Notion / Asana

Beide haben **Free-Tier** der reicht:
- Notion Free: unbegrenzte Pages, kein Backup-Limit.
- Asana Free: 15 User, 1000 Tasks pro Liste, kein Timeline-Feature.

Wenn du auf Pro/Team upgrades: jaehrlich zahlen ist meist 15-20% billiger.

## Wenn ein Key leakt

1. **Sofort** beim Provider widerrufen (Revoke-Knopf neben dem Key).
2. Ueberlauf-Charges: bei OpenAI/Anthropic kannst du Support kontaktieren — meist erlassen sie missbraeuchliche Charges einmalig.
3. Logs (z.B. `docker logs zf-bot`) auf ungewoehnliche Anfragen pruefen.
4. Neuen Key generieren, `.env` updaten, `update.sh` laufen lassen.
