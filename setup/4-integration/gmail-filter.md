# Gmail-Filter -> Cloudflare Email Routing -> Worker -> Bot

Ein einmaliges Setup. Danach landet jede Mail mit dem Label `ZF`
automatisch im Bot, wird klassifiziert und in Notion gespeichert.

## 1. Cloudflare Email Routing aktivieren

1. Cloudflare Dashboard -> deine Domain -> **Email** -> **Email Routing**
   aktivieren. CF setzt MX/TXT-Records automatisch.
2. Unter **Routes** -> **Custom address**:
   - `inbox@deine-domain`
   - Action: **Send to Worker** -> Worker `zf-mail` (siehe naechster Schritt).

## 2. Worker deployen

```
npm i -g wrangler
wrangler init zf-mail               # JS, kein TypeScript
# Inhalt von setup/4-integration/cloudflare-worker.js in src/worker.js kopieren
wrangler secret put WEBHOOK_SECRET  # gleicher Wert wie .env auf dem VPS
wrangler secret put BOT_URL         # z.B. https://bot.deine-domain
wrangler deploy
```

In `wrangler.toml` benoetigt:
```
name = "zf-mail"
main = "src/worker.js"
compatibility_date = "2024-09-01"
```

`postal-mime` ist im Worker-Runtime out-of-the-box verfuegbar (npm install
nur lokal fuer Linting).

## 3. Gmail-Filter

1. Gmail -> Settings -> **Forwarding and POP/IMAP** -> *Add a forwarding
   address* -> `inbox@deine-domain`. CF schickt eine Bestaetigungsmail
   dorthin (sie laeuft durch den Worker -> erstmal Worker auf "echo" oder
   die Adresse temporaer auf "Send to email" stellen, Code copy-pasten,
   anschliessend wieder auf "Send to Worker" zurueck).
2. Gmail -> Settings -> **Filters and Blocked Addresses** -> *Create a
   new filter*.
3. Kriterium z.B. `subject:[ZF]` oder `from:rechnung@...` oder
   `has:attachment`.
4. Aktion:
   - [x] Apply the label: **ZF** (Label vorher anlegen)
   - [x] Forward it to: `inbox@deine-domain`
   - optional [x] Skip the Inbox

## 4. Test

- Mail mit Subject `[ZF] Bahnticket 49 EUR` an dich selbst schicken.
- Innerhalb von ~30s sollte ein Eintrag in Notion (Costs) erscheinen.
- Kontrolle: `docker logs -f zf-bot` zeigt `[mail] from=... kind=cost ...`.

## Troubleshooting

- 401 vom Bot: `WEBHOOK_SECRET` in `.env` und Worker-Secret stimmen nicht.
- 503 vom Bot: `WEBHOOK_SECRET` ist nicht gesetzt oder zu kurz (<32).
- Mail kommt nicht: Cloudflare -> Email -> "Activity" zeigt Routing-Logs.
- Worker-Fehler: `wrangler tail zf-mail` zeigt Live-Logs.
