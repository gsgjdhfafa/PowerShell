# Google OAuth Setup — Schritt fuer Schritt

Ziel: Du bekommst am Ende drei Werte fuer `setup/3-bot/.env`:
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
GOOGLE_TASKS_LIST_ID=...
```

Dauer: ~10 Minuten beim ersten Mal. Danach nie wieder.

---

## Teil 1 — Google Cloud Console (Browser, einmalig)

### 1.1 Projekt anlegen

1. https://console.cloud.google.com oeffnen.
2. Oben links die Projekt-Auswahl klicken (steht „Select a project").
3. **„NEW PROJECT"** rechts oben.
4. Name: `zf` (oder was du willst). Organisation/Standort kannst du leer lassen.
5. **„CREATE"** druecken.
6. Warten ~5 Sekunden, dann oben links das **`zf`-Projekt** auswaehlen.

### 1.2 APIs einschalten

Zwei APIs brauchst du. Fuer jede:

1. Linkes Menue → **„APIs & Services"** → **„Library"**.
2. In die Suche: `Google Tasks API` → klicken → **„ENABLE"**.
3. Zurueck zur Library, suchen: `Google Calendar API` → klicken → **„ENABLE"**.

### 1.3 OAuth Consent Screen einrichten

1. Linkes Menue → **„APIs & Services"** → **„OAuth consent screen"**.
2. **User Type: External** → **„CREATE"**.
3. Felder ausfuellen:
   - **App name**: `zf`
   - **User support email**: deine Mail
   - **Developer contact email**: deine Mail
4. **„SAVE AND CONTINUE"**.
5. **Scopes**: nichts hinzufuegen → **„SAVE AND CONTINUE"**.
6. **Test users**: deine Google-Mail eintragen → **„ADD"** → **„SAVE AND CONTINUE"**.
7. **„BACK TO DASHBOARD"**.
8. **WICHTIG**: Auf der Uebersicht ganz oben **„PUBLISH APP"** klicken → bestaetigen.
   - Status sollte auf **„In production"** wechseln.
   - App bleibt **„unverified"** — das ist okay, du bist dein eigener Test-User.
   - **Wenn du diesen Schritt UEBERSPRINGST**, laeuft dein Refresh-Token nach **7 Tagen** ab und der Bot stoppt. Also nicht ueberspringen.

### 1.4 OAuth Client ID erstellen

1. Linkes Menue → **„APIs & Services"** → **„Credentials"**.
2. Oben **„+ CREATE CREDENTIALS"** → **„OAuth client ID"**.
3. **Application type**: **Desktop app**.
4. **Name**: `zf-cli`.
5. **„CREATE"**.
6. Popup zeigt:
   - **Client ID**: `123-...apps.googleusercontent.com`
   - **Client secret**: `GOCSPX-...`
7. **Beide Werte kopieren** und kurz parken (Notepad). Du kommst auch jederzeit wieder dran ueber Credentials → den Eintrag anklicken.

---

## Teil 2 — Lokal: oauth-helper.mjs ausfuehren

### 2.1 Repo lokal sicherstellen

Wenn du das Repo noch nicht lokal hast, in PowerShell:

```powershell
gh repo clone gsgjdhfafa/PowerShell
cd PowerShell
git checkout claude/setup-system-architecture-DvgRI
git pull
```

Wenn schon da: nur `git pull`.

### 2.2 Helper starten

```powershell
node setup\4-integration\oauth-helper.mjs
```

Was dann passiert:

```
GOOGLE_CLIENT_ID:     [hier deine Client-ID einfuegen + Enter]
GOOGLE_CLIENT_SECRET: [hier dein Client-Secret einfuegen + Enter]
```

→ Browser oeffnet sich mit Google-Login.

### 2.3 Im Browser

1. Mit dem **gleichen Account** einloggen, den du als Test-User eingetragen hast.
2. Eine Warnseite **„Google hasn't verified this app"** kommt → unten **„Advanced"** klicken → **„Go to zf (unsafe)"** klicken.
3. Zwei Berechtigungsfragen → bei beiden **„Allow"**:
   - „See, edit, and permanently delete the tasks…"
   - „See, edit, share, and permanently delete the calendars…"
4. Tab schliesst sich mit **„ok. Tab schliessen."**

### 2.4 Im Terminal steht jetzt

```
--- in setup/3-bot/.env eintragen ---
GOOGLE_CLIENT_ID=123-xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxxxx
GOOGLE_REFRESH_TOKEN=1//09xxxxxxxxxxxxxxxxxxxxxxxxx
GOOGLE_TASKS_LIST_ID=MTk1NDU2... # Standardliste

# weitere Listen:
# MTI3NDQ... Arbeitstasks
# MTk5...   Privat
GOOGLE_CALENDAR_ID=primary
```

→ **Diesen Block 1:1** speichern. Spaeter (in **Block 5**) einfuegen in die `.env` auf dem VPS.

---

## Wenn was nicht klappt

| Fehler                                    | Loesung                                             |
|-------------------------------------------|-----------------------------------------------------|
| `Kein refresh_token erhalten`             | Google-Account → Sicherheit → Drittanbieter-Zugriff → `zf` entfernen → Helper nochmal starten. Bei `prompt=consent` muss er kommen. |
| Browser zeigt „Access blocked: zf has not completed Google verification" und KEIN „Advanced"-Link | Du bist mit dem falschen Google-Konto eingeloggt (kein Test-User). Konto wechseln oder unter Consent Screen → Test users dein Konto eintragen. Oder die App ist nicht „in production" gesetzt — Schritt 1.3.8 nachholen. |
| `Port 53672 already in use`               | Ein anderes Skript haengt. PowerShell-Fenster schliessen + neu, oder im Helper-File `PORT = 53673` setzen. |
| `node: command not found`                 | Node.js fehlt. Run `winget install OpenJS.NodeJS.LTS` oder `setup\1-pc\dev-setup.ps1`. PowerShell neu oeffnen. |
| Helper fragt nach Client-ID, ich tippe nichts kommt an | PowerShell-Window aktiv? Sonst klick rein. |
| `Cannot find package 'undici'`            | Ist nicht noetig — Helper benutzt nur Native Node + global `fetch` (Node 20+). Sicher dass du Node 20+ hast: `node --version`. |

---

## Wenn du fertig bist

→ Sag „**Block 2 fertig**" (oder zeig mir nur die ersten 6 Zeichen vom REFRESH_TOKEN), dann gehen wir Block 3 (Cloudflare) an.
