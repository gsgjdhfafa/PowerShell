# Risiken + Hygiene — was du beachten solltest

Priorisiert nach „wenn das schiefgeht, wird's teuer/schlimm".

## Inhalt

1. [Secrets / API-Keys](#1-secrets--api-keys)
2. [Fristen (Insolvenz + Betreuung)](#2-fristen-insolvenz--betreuung)
3. [Datenschutz / Mail-Inhalte](#3-datenschutz--mail-inhalte)
4. [Kein Auto-Vertrauen in KI](#4-kein-auto-vertrauen-in-ki)
5. [Single Points of Failure](#5-single-points-of-failure)
6. [Backup + Disaster Recovery](#6-backup--disaster-recovery)
7. [Kosten unter Kontrolle](#7-kosten-unter-kontrolle)
8. [Quellen-der-Wahrheit-Konflikt](#8-quellen-der-wahrheit-konflikt)
9. [Repo-Struktur (Fork-Problem)](#9-repo-struktur-fork-problem)
10. [Wartung / Monitoring](#10-wartung--monitoring)
11. [Migration auf neuen PC](#11-migration-auf-neuen-pc)

---

## 1. Secrets / API-Keys

Du sammelst gerade einen Stapel Tokens an: Telegram, Notion, Google (Refresh Token!), Cloudflare, OpenAI/Claude API, Webhook-Secret.

**Regeln**:
- **Niemals** `.env` committen — `.gitignore` hat sie schon, aber pruefen: `git check-ignore -v setup/3-bot/.env` muss „ignored" sagen.
- **Niemals** in Chat / Issues / Mails reinpasten. Auch nicht „nur die ersten 6 Zeichen". Wenn doch passiert ist → **rotieren**.
- Den `WEBHOOK_SECRET` aus diesem Chat (`ee18d4...`) **vor Produktion neu generieren** — der hat in einem AI-Chat gestanden, gilt als kompromittiert.
- Tokens **rotieren**: Notion-Integration jaehrlich, Google-Refresh wenn ungewoehnliches Verhalten, OpenAI/Claude bei Verdacht.
- API-Keys mit **Limits** erstellen wo moeglich (OpenAI hat Spending-Caps, nutze sie).

**Wenn ein Key leakt**:
1. Sofort beim Provider widerrufen (revoke).
2. Neuen anlegen.
3. `.env` updaten + `update.sh` laufen lassen.

---

## 2. Fristen (Insolvenz + Betreuung)

Stufen 3 + 4 deiner Pipeline sind **fristengetrieben** — eine vergessene Frist kann existenziell sein.

**Doppelte Sicherung Pflicht**:
- Frist in **Notion** (Tasks) + **Google Calendar** + zusaetzlich physische Notiz / Sticky-Note.
- Calendar-Erinnerung **2x**: 7 Tage und 1 Tag vorher.
- Keine Frist nur im Bot — der Bot kann ausfallen.

**Kein Auto-Bezahlen / Auto-Versenden**:
- Goldene Regel ist „Mensch entscheidet".
- Wenn du den Bot mal erweiterst (z.B. Auto-Reply): **Whitelist-Pflicht**, nicht Blacklist.

---

## 3. Datenschutz / Mail-Inhalte

Wenn der Bot Gmail-Mails klassifiziert, gehen die durch:
- Cloudflare Email Routing (CF sieht die Mails)
- Cloudflare Worker (laeuft auf CF-Servern)
- Dein VPS (deutscher/EU-Anbieter? Hetzner = ja)
- OpenAI **oder** Claude (US-Server) **oder** Ollama (lokal)
- Notion (US-Server)

**DSGVO-Implikationen**:
- Insolvenz- und Betreuungssachen sind potenziell **besondere personenbezogene Daten** (Gesundheit, Finanzen).
- Empfehlung: fuer **sensible** Briefe (3. + 4. Pipeline-Stufe) **NUR** Ollama lokal benutzen, kein Cloud-LLM.
- Im `classifier.js` koenntest du eine Heuristik einbauen: wenn Subject `betreuung|insolvenz|gericht` → AI_PROVIDER=ollama, sonst Claude.

**Logs**:
- Mail-Body wird im Bot **nie** geloggt — bestaetigt in `server.js`. Bitte so lassen.
- Wenn du das aenderst, beachte: Docker-Logs liegen auf dem VPS und in Backups.

---

## 4. Kein Auto-Vertrauen in KI

KI klassifiziert + extrahiert, aber sie **halluziniert**:

| Was schiefgehen kann                    | Konsequenz                          | Sicherung                                   |
|-----------------------------------------|-------------------------------------|---------------------------------------------|
| Datum extrahiert: `2026-15-32`         | Calendar-Event-Fehler, ungueltig    | Datum nach Extraktion validieren (`Number.isFinite(new Date(due).getTime())`) |
| Cost-Amount halluziniert (`amount: 0`)  | falsche Buchhaltung                 | hast du schon gefixt — Pflichtfeld          |
| Phishing-Mail als „Rechnung" eingestuft | du zahlst eine Fake-Rechnung        | NIE ohne menschlichen Blick zahlen          |
| Mail-Inhalt im Subject als Befehl        | Prompt-Injection                    | im System-Prompt klar trennen + Treaten als Daten |
| Modell wurde geupdated, anderes Verhalten| inkonsistente Klassifikation        | Modell-Versionen pinnen (du machst das schon: `claude-opus-4-7`) |

**Faustregel**: Bot ist Vorschlag, du bist Entscheider. Erst recht bei Geld, Fristen, Behoerden.

---

## 5. Single Points of Failure

| Komponente faellt aus       | Folge                                   | Was tun (manueller Fallback)                |
|------------------------------|-----------------------------------------|---------------------------------------------|
| VPS down                     | Bot reagiert nicht                      | Notion direkt im Browser benutzen           |
| Cloudflare Tunnel zickt      | Mails kommen nicht an                   | Gmail manuell triagieren bis fixed          |
| Cloudflare Account locked    | Domain + Mail + Tunnel weg              | Domain-Registrar haben? Wenn nicht: Backup-Domain |
| Notion API down              | Bot kann nicht schreiben                | Bot-Logs zeigen Fehler, danach manuell nachtragen |
| OpenAI/Claude down           | Klassifizierung haengt                  | Im `.env` Provider auf den anderen wechseln |
| Google Account gesperrt      | Mail/Calendar/Tasks alles weg           | **Recovery-Codes ausgedruckt aufbewahren!** |

**Regel**: jede Komponente sollte **manuell ersetzbar** sein. Wenn du fuer X ohne Bot nicht arbeiten kannst, ist X zu wichtig fuer „nur Bot".

---

## 6. Backup + Disaster Recovery

### Was muss gesichert sein

| Daten                   | Wo                               | Backup wie                                           |
|-------------------------|----------------------------------|------------------------------------------------------|
| Repo                    | GitHub + lokaler Clone           | redundant, ok                                        |
| `.env` auf VPS          | `/home/ops/app/setup/3-bot/.env` | per `scp` oder Bitwarden Secure Note kopieren        |
| Notion-Datenbanken      | Notion Cloud                     | Notion → Settings → Workspace → Export jaehrlich     |
| Google-Daten            | Google Cloud                     | Google Takeout halbjaehrlich                          |
| VPS-Snapshot            | Hetzner Snapshot                 | Hetzner Konsole → Snapshot vor groesseren Aenderungen |
| `C:\Users\Admin\Briefe` | lokal auf PC                     | wegsichern auf Drive verschluesselt + externe HDD    |

### Recovery-Test

Mindestens **einmal jaehrlich**:
1. Notion-Export herunterladen, in einer leeren Workspace re-importieren — gehen alle Verknuepfungen?
2. VPS-Snapshot wiederherstellen, `doctor.sh` laufen lassen — laeuft alles wieder?

---

## 7. Kosten unter Kontrolle

Stapel der laufenden Kosten:

| Posten                 | typische Hoehe         | wo abrufbar                    |
|------------------------|------------------------|--------------------------------|
| VPS Hetzner CX22       | ~4 €/Monat             | Hetzner Cloud Console           |
| Domain                 | 5-15 €/Jahr            | Registrar                       |
| OpenAI API             | $0.50-5/Monat (klein)  | platform.openai.com → Usage    |
| Anthropic API          | aehnlich                | console.anthropic.com → Usage  |
| Cloudflare             | 0 €                    | gratis-Tier reicht              |
| Notion Free            | 0 €                    | reicht oft                      |
| Asana Free             | 0 €                    | reicht oft                      |
| ChatGPT Plus           | 20 $/Monat              | wenn du das Web-UI nutzt        |
| Claude Pro             | 20 $/Monat              | wenn du das Web-UI nutzt        |
| Cursor Pro             | 20 $/Monat              | wenn du Cursor nutzt            |

**Kosten-Limits setzen**:
- OpenAI: platform.openai.com → Settings → Limits → **Hard limit** (z.B. 20$/Monat)
- Anthropic: console.anthropic.com → Plans → Spend Limit
- Telegram-Bot: AI-Calls cappen via Provider-Limit (siehe oben). Im Bot zusaetzlich pro-User-Limit waere sinnvoll, aber nice-to-have.

---

## 8. Quellen-der-Wahrheit-Konflikt

Du hast jetzt potenziell **drei** Aufgaben-Listen:
- **Notion Tasks** (durch Bot beschrieben)
- **Google Tasks** (Sync-Ziel)
- **Asana** (operativ)

**Risiko**: Aufgabe nur in einem System, du suchst sie woanders.

**Klare Regel definieren** (vorgeschlagen):
- **Notion** = Strategie, Pipeline-Stufen, Memory.
- **Google Tasks** = persoenliche To-dos die im Handy als Notification erscheinen sollen.
- **Asana** = nur **Triton GmbH operativ** + Briefe-Triage.

Bot schreibt nur in Notion + Google (von dort der Sync). Asana fasst er nicht an, ist menschliche Domaene.

---

## 9. Repo-Struktur (Fork-Problem)

`gsgjdhfafa/PowerShell` ist ein Fork von `PowerShell/PowerShell` (Microsoft). Dein `setup/`-Ordner liegt da drin als Subfolder.

**Probleme die kommen**:
- Wenn du upstream pullst, kommen 1000ende Files mit, die nichts mit dir zu tun haben.
- CI von upstream koennte deine `setup/`-Aenderungen abweisen (.NET Build-Skripte).
- Bei einem Force-Push von upstream koennte dein Branch gerade gebrochen werden — passiert dir hier nicht weil dein Branch auf `master` umbasiert ist, aber theoretisch.

**Empfehlung mittelfristig** (nicht jetzt):
- **Eigenes Repo** anlegen: `gsgjdhfafa/zf-setup` o.ae., nur den `setup/`-Ordner uebernehmen.
- Vorteil: kein 200-MB-Clone, keine Konflikte, eigene CI-freie Welt.
- Aufwand: 10 Minuten. Ich kann das Repo-File-Layout sauber rauskopieren wenn du willst.

---

## 10. Wartung / Monitoring

- **Woechentlich**: Telegram `/status` druecken — laeuft der Bot? Notion ok? Google ok?
- **Woechentlich**: `doctor.sh` ueber SSH laufen lassen.
- **Monatlich**: Container-Updates: `update.sh` (zieht neue Images + Code).
- **Monatlich**: Disk-Space pruefen (`df -h /`), `docker system prune -f` wenn voll.
- **Quartalsweise**: Logs durchgehen, ungewoehnliches Verhalten? `docker logs zf-bot --since 30d | grep -i error`.

**Telegram-Alarm bei Bot-Crash** (nice to have):
- VPS hat noch keinen Watchdog der Telegram pingt wenn Container down ist.
- Loesung: Cron-Job auf VPS, `docker ps | grep zf-bot || curl Telegram-API`. 5 Minuten Aufwand. Sag wenn du das willst.

---

## 11. Migration auf neuen PC

Wenn du neuen PC einrichtest, was musst du dabei haben:

1. **Bitwarden** mit Master-Password — alle Logins zurueck.
2. **GitHub** Account — Repo wieder clonen.
3. **Google** Account + Recovery-Codes — Mail/Calendar/Tasks zurueck.
4. **SSH-Key** fuer den VPS — entweder neu anlegen + auf VPS hinterlegen, oder alten Key sicher uebertragen (`scp` ueber jumphost / Bitwarden Secure Note).

**Aus dem nichts neu in unter 1h**:
```powershell
# 1. Brave + Bitwarden + Tools
powershell -ExecutionPolicy Bypass -File setup\1-pc\run-all.ps1 `
    -GitName 'Vorname Nachname' -GitEmail 'du@example.com'

# 2. Bitwarden entsperren -> Logins zurueck

# 3. SSH-Key vom dev-setup.ps1-Output in GitHub eintragen, gh auth login

# 4. Alles laeuft.
```

VPS bleibt unberuehrt (Cloud), der ist von jedem Rechner gleich erreichbar.
