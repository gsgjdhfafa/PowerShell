# 05-vr · PICO 4 Ultra (VR-Client)

Standalone VR-Headset, ByteDance/Pico, PICO OS (Android-basiert).
Rolle: zusaetzlicher Cloud-Client. **Kein Backend-Change**, kein Bot-Change.

Telegram + Notion + Google laufen als Android-Apps bzw. im PICO Browser.
Der bestehende `TELEGRAM_ALLOWED_USER_ID`-Lock greift automatisch — selbe User-ID, neues Geraet.

Hintergrund / Profil-Match / Anti-Hype-Liste: siehe [USE-CASES.md](./USE-CASES.md).

---

## Provisionierung (einmalig, auf dem Headset)

### 1. Accounts (alle identisch zum PC)

- Google Workspace (Gmail / Calendar / Tasks / Drive)
- Notion (gleicher Workspace)
- Telegram (gleicher User wie auf PC; Login-Code via SMS oder anderer Telegram-Session)

### 2. Apps installieren

Aus dem **PICO Store** (sofern verfuegbar) oder via **SideQuest** als Android-APK:

| App      | Quelle              | Zweck                              |
|----------|---------------------|------------------------------------|
| Telegram | PICO Store / APK    | Primaerer Bot-Eingabekanal         |
| Notion   | PICO Store / APK    | Memory / Tasks / Costs Dashboard   |
| Brave    | APK (optional)      | Browser, falls PICO Browser nicht reicht |

Reihenfolge egal. Keine Geraete-spezifischen Einstellungen noetig.

### 3. Browser-Bookmarks (PICO Browser oder Brave Android)

Identisch zum PC-Setup aus `01-pc/brave-setup.ps1`:

- `https://www.notion.so`
- `https://mail.google.com`
- `https://calendar.google.com`
- `https://tasks.google.com`

### 4. Telegram-Bot anpingen

```
/start
```

Bot antwortet → Setup fertig. Falls keine Antwort: User-ID stimmt nicht mit `TELEGRAM_ALLOWED_USER_ID` ueberein.

---

## Voice-Flow (VR-Vorteil)

```
PICO Mic → Telegram Diktat-Button → Text → Bot → KI → Notion → Push-Antwort
```

Haendefreies `/note ...`, `/task ...`, `/cost ...` ohne Custom-Code.
Funktioniert out of the box, weil Telegram Android das System-Mic nutzt.

---

## Was bewusst NICHT gemacht wird

- **Keine eigene VR-App** — verletzt "Minimal lokale Apps".
- **Kein zweiter Telegram-Account** — verletzt "Keine Redundanzen".
- **Keine Avatar/Workrooms-Integration** — out of scope, nicht zero-friction.
- **Keine VPS-seitigen Aenderungen** — Telegram Push reicht als Notification-Kanal.

---

## Troubleshooting

| Symptom                          | Ursache                                  | Loesung                                         |
|----------------------------------|------------------------------------------|-------------------------------------------------|
| Bot antwortet nicht              | falsche User-ID im VPS `.env`            | `TELEGRAM_ALLOWED_USER_ID` pruefen, identisch fuer alle Geraete |
| Telegram-Login schlaegt fehl     | Login-Code geht nur an aktive Session    | Code in PC- oder Phone-Telegram annehmen        |
| Notion-App laed nicht            | PICO Store hat veraltete Version         | aktuelle APK via SideQuest sideloaden           |
| Voice-Diktat liefert leeren Text | PICO Mic-Permission nicht erteilt        | App-Permissions → Mikrofon erlauben             |

---

## Verification

1. `/start` von VR → Bot-Antwort kommt
2. `/note Test aus VR` → Notion-URL zurueck → Eintrag erscheint in Memory-DB
3. PICO Browser → Notion-Workspace identisch zum PC sichtbar
4. Voice: Mic-Button → "Erstelle Task: Domain bezahlen" → Eintrag in Tasks-DB

Keine Tests / Builds. VR ist reiner Cloud-Client.
