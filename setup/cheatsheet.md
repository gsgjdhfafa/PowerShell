# Workspace Cheatsheet

Praktisch, in Deutsch, mit Beispielen. Englische Fachbegriffe stehen in (Klammern).

---

## 1. HOTKEYS — was passiert wenn du sie drueckst

| Hotkey            | Was passiert                              | In welchem Account                       |
|-------------------|-------------------------------------------|------------------------------------------|
| `Shift+F1`        | Gmail oeffnet                             | **Gerrit (Master)** — dein Hauptaccount  |
| `Shift+F2`        | Gmail oeffnet                             | **TTT (Taucher)** — Triton-Account       |
| `Shift+F3`        | Gmail oeffnet im Comet                    | **TTT-Pro** — Triton Premium             |
| `Shift+F4`        | Google Kalender                           | **Gerrit (Master)**                      |
| `Shift+F6`        | Google Kalender                           | **TTT (Taucher)**                        |
| `Shift+F7`        | Google Drive                              | **Gerrit (Master)**                      |
| `Shift+F8`        | Google Drive                              | **TTT (Taucher)**                        |
| `Shift+F9`        | NotebookLM                                | **Gerrit (Master)** — deine 6 Buecher    |
| `Shift+F10`       | Asana (Aufgaben)                          | **TTT-Pro**                              |
| `Shift+F11`       | ASKGENT (lokaler Bot)                     | lokal, kein Account                      |
| `Shift+Strg+F3`   | 3 Comet-Fenster mit TTT-Pro auf einmal    | **TTT-Pro**                              |

### Allgemeine Tasten (gehen ueberall)

| Hotkey            | Was passiert                          |
|-------------------|---------------------------------------|
| `Strg+C`          | Kopieren                              |
| `Strg+V`          | Einfuegen                             |
| `Strg+X`          | Ausschneiden                          |
| `Strg+Tab`        | Tab nach rechts (im Browser)          |
| `Strg+Shift+Tab`  | Tab nach links                        |
| `Win+N`           | Neue Sticky-Note (kleiner gelber Zettel) |
| `Win+Alt+T`       | Watcher-Skript: Triton-Modus          |
| `Win+Alt+D`       | Watcher-Skript: Drive-Modus           |
| `Win+Alt+G`       | Watcher-Skript: Gerrit-Modus          |
| `Vol +/-` / `Mute`| Lautstaerke / Stumm                   |
| `Skip <- / ->`    | Lied vor / zurueck                    |

> Die F-Tasten sind in `C:\Users\Admin\account-shortcuts.ahk` definiert. Das ist ein **AutoHotkey**-Skript (kleines Programm, das Tasten umbiegt). Wenn was nicht geht: doppelklick auf die `.ahk`-Datei → laeuft wieder.

---

## 2. Wichtige Pfade — wo lebt was

| Bereich         | Pfad                                                  | Zweck                                          |
|-----------------|-------------------------------------------------------|------------------------------------------------|
| Briefe-Triage   | `C:\Users\Admin\Briefe`                                | 4 Unterordner: Inbox / Pending / Processing / Done |
| Briefe-Bin      | `C:\Users\Admin\Briefe\Bin`                            | Skripte: `classify.py`, `diagnose.py`           |
| Triton CC       | `C:\Users\Admin\Dashboard`                             | Web-Dashboard (laeuft auf Port 7777)            |
| CC-Module       | `C:\Users\Admin\Dashboard\modules`                     | Start-Skripte `start-*.ps1`                     |
| Wallpapers      | `C:\Users\Admin\Wallpapers`                            | erzeugen + ueber alle Monitore spannen          |
| Notes Daemon    | `C:\Users\Admin\Notes`                                 | Sticky-Notes via `Win+N`                        |
| Task Scanner    | `C:\Users\Admin\TaskScanner`                           | WPF-Fenster, immer oben                         |
| Ask Window      | `C:\Users\Admin\Ask`                                   | dein lokaler Bot (Ollama qwen2.5:7b)            |
| Account-AHK     | `C:\Users\Admin\account-shortcuts.ahk`                 | alle F-Tasten                                   |
| Watcher-AHK     | `C:\Users\Admin\watcher-shortcuts.ahk`                 | `Win+Alt+T/D/G`                                 |

---

## 3. Goldene Regeln (auf Deutsch ohne Tech-Sprech)

- **Drive-Sammelordner**: Originale **niemals** verschieben — nur **Kopien** in den Sammel-Ordner.
- **Chrome immer mit Profil**: jedes Chrome-Fenster braucht ein Profil. Sonst mischt es Mails und Daten zwischen den Accounts.
- **Comet-Standard = TTT**: das voreingestellte Profil heisst **Neptun** und gehoert zu TTT-Pro Premium. Erst aktiv aendern wenn du es willst.
- **Fenster oeffnen sich auf dem Monitor, wo gerade die Maus ist** — nicht immer auf dem Hauptmonitor.
- **1 Profil = 1 Fenster**: Tabs sammeln sich im selben Fenster pro Profil. Nicht jedes Mal `--new-window`.
- **Briefe-Triage**: OCR (Texterkennung) plus KI-Klassifizierung — **du** entscheidest, was rausgeht. **Kein** Auto-Versand, **kein** Auto-Bezahlen.
- **MEMORY ist die einzige Wahrheit**: `MEMORY.md` ist der Index. Einzelne `.md`-Dateien sind die Quellen. Nichts doppelt schreiben.
- **Kein VS / VS Code im Alltag**: nutze Notepad, Browser oder PowerShell. (Trotzdem hilft VS Code wenn du mal Code anfasst — siehe Sektion „VS CODE".)
- **Dieser Chat ist nur fuer PC-Optimierung** — Triton-Inhalte und Recht in eigene Chats packen.
- **3-Desktop-Modell**:
  - **D1** = Monitoring (alles im Blick)
  - **D2** = Projects (genau **eine** Aufgabe)
  - **D3** = Dev/Sandbox (zum Spielen)
- **Triton CC fokus**: Workspace neu „snappen" (Fenster wieder in Position bringen) — nicht abdriften lassen.

---

## 4. Pipeline TOP-4 (Reihenfolge nach Wichtigkeit)

| # | Stufe       | Was zu tun ist                                                        |
|---|-------------|-----------------------------------------------------------------------|
| 1 | PITCH       | Pitch + Business-Plan + Anhang + TV-Aussage + Know-how (KI4KI)        |
| 2 | BEWERBUNG   | Programm-Calls KI4KI + Taucherteam Triton GmbH                        |
| 3 | INSOLVENZ   | Widerspruch einlegen, Fristen so weit wie moeglich verlaengern        |
| 4 | BETREUUNG   | Vorfall an Jugendamt melden + Termin + Oberlandesgericht              |

---

## 5. Workflows TOP-5 (wie laeuft der Tag)

| Workflow         | Schritte                                                                   |
|------------------|----------------------------------------------------------------------------|
| Briefe-Pipeline  | Scan → OCR → Ollama klassifiziert → Triage → Inbox/Pending/Done            |
| Tasks-Pipeline   | `Pipeline.md` (Top-4) → Asana operativ → wer arbeitet woran                |
| Knowledge        | NotebookLM (Master, 6 Buecher, ~235 Quellen) — Hotkey `Shift+F9`           |
| Mail-Triage      | Gmail Gerrit/TTT/Comet → Briefe-Triage → Antworten oder Archiv             |
| Code-Workflow    | PowerShell direkt | AHK Skripte | Python in `Briefe\Bin` | KEIN VS Code   |

---

# KI-TOOLS — was, wo, wofuer

## OpenAI ChatGPT
- **Webseiten**: `chatgpt.com` oder `chat.openai.com`
- **Modelle**: GPT-4o (kann Bilder), GPT-4.5, o1/o3 (denkt nach), gpt-image-1 (Bilder erzeugen)
- **Tasten**: `Strg+Enter` senden, `Strg+Shift+O` neuer Chat, `Strg+/` springt in das Eingabefeld
- **Features**: Memory (merkt sich Sachen), Custom Instructions, Projects, Canvas, Voice
- **Kosten**: Plus 20$/Monat, Team 25$/User, Pro 200$/Monat (mit o1-pro)

## Anthropic Claude — was du gerade benutzt
- **Webseiten**: `claude.ai`, `console.anthropic.com`
- **Modelle**: Sonnet 4.6 (Standard, schnell), Opus 4.6 (denkt tiefer, langsamer), Haiku 4.5 (am schnellsten)
- **Apps**: Claude Desktop (`.msix` installieren), **Claude Code** (Terminal-Tool, im Terminal `claude` tippen), claude.ai im Browser
- **Tasten**: `Strg+Enter` senden, `Strg+K` neuer Chat, `Strg+/` Befehlspalette
- **Features**: Projects (Sammlung), Artifacts (Code-Vorschau), Computer-Use (kann den PC bedienen), Memory (automatisch)

## Google Gemini + NotebookLM
- `gemini.google.com` — 2 Millionen Zeichen Kontext, kann auch Bilder
- `aistudio.google.com` — fuer API-Tests + System-Prompts feinschleifen
- `notebooklm.google.com` — du gibst Quellen rein, dann Q&A. (Im Comet-Browser eingebaut!)
- **Modelle**: Gemini 2.5 Pro / Flash, Gemma3 (lokal nutzbar), Imagen 4 (Bilder)
- **Tasten**: `Strg+Enter` senden. Ein `/` im Eingabefeld zeigt Slash-Befehle.

## Perplexity Comet (der Browser)
- **App**: `C:\Program Files\Perplexity\Comet\Application\comet.exe`
- **Profile**:
  - Default = **Neptun** (TTT-Pro)
  - Profile1 = **Gerrit** (KI4KI)
- **Sidebar (Seitenleiste)**:
  - Sidekick — `Alt+L` (KI-Helfer rechts)
  - Tasks-Panel (Aufgabenliste)
  - Tab-Assistant (hilft beim Tabs sortieren)
- **Was Pro kann**: Comet-Assistent in **jedem** Tab, Web-Aktionen ausfuehren, Spaces (thematische Container)
- **Tasten**: `Strg+T` neuer Tab, `Strg+Shift+L` Sidekick, `Strg+J` Tasks

## Perplexity (im Web)
- **URL**: `perplexity.ai` oder kurz `pplx.ai`
- **Modelle**: Sonar (eigenes), Claude, GPT-4, Grok — du waehlst pro Anfrage
- **Spaces**: Container fuer Themen mit eigenen Prompts + hochgeladenen Dateien
- **Pro**: 20$/Monat, Sonar-API, Bild-Erzeugung
- **Tasten**: `Strg+Shift+P` Pro-Modus, `Strg+I` Bild-Modus

## Cursor IDE — eine spezielle Code-Werkstatt
- **Was ist das**: ein Editor wie VS Code, aber mit eingebauter KI. Holst du dir auf `cursor.com`.
- **Tasten**:
  - `Strg+K` — KI veraendert markierten Code direkt
  - `Strg+L` — KI-Chat seitlich
  - `Strg+I` — „Composer" macht groessere Aenderungen ueber mehrere Dateien
- **Modelle**: Claude Sonnet/Opus, GPT-4o, o1
- **`.cursorrules`**: das ist eine **Regeldatei** im Projekt-Ordner. Du schreibst da rein „antworte immer auf Deutsch" oder „nutze Tabs statt Spaces". Cursor liest sie automatisch beim Start.
- **Kosten**: Hobby kostenlos, Pro 20$/Monat

---

# OLLAMA — dein lokaler KI-Server (Tutorial)

> Ollama laesst KI-Modelle **direkt auf deinem PC** laufen. Kein Internet noetig, keine Daten gehen raus. Genau das Ding hinter deinem `Ask`-Fenster (qwen2.5:7b lokal).

## A. Installation

In **PowerShell** tippen:
```powershell
winget install Ollama.Ollama
```
Fertig. Ollama laeuft danach im Hintergrund (Tray-Icon unten rechts). Wenn nicht: `ollama serve` in einer PowerShell starten und das Fenster offen lassen.

## B. Erstes Modell holen + nutzen

```powershell
ollama run qwen2.5:7b
```
Beim **ersten** Lauf:
1. laedt das Modell runter (~4-5 GB) — einmal.
2. wirft dich in einen **Chat** im Terminal — du tippst, Enter, KI antwortet.

So sieht's aus:
```
>>> Was ist die Hauptstadt von Frankreich?
Paris ist die Hauptstadt von Frankreich.

>>> /bye
```
Mit `/bye` (oder `Strg+D`) verlaesst du den Chat.

## C. Modelle wechseln

| Modell                  | Groesse | Wofuer                                         |
|-------------------------|---------|------------------------------------------------|
| `qwen2.5:7b`            | ~4 GB   | dein Standard, schnell, kann Deutsch           |
| `llama3.2:3b`           | ~2 GB   | klein + schnell, fuer einfache Klassifizierung |
| `llama3.1:8b`           | ~5 GB   | etwas besser bei Logik                         |
| `mistral:7b`            | ~4 GB   | gut bei Code                                   |
| `phi3:medium`           | ~8 GB   | von Microsoft, kompakt fuer Reasoning          |
| `gemma3:4b` / `gemma3:12b` | 3/8 GB | Google, schnelle Antworten                   |
| `qwen2.5-coder:7b`      | ~4 GB   | speziell fuer Code                             |

So holst du dir eins:
```powershell
ollama pull llama3.2:3b
```

So schaust du was du schon hast:
```powershell
ollama list
```

So loescht du eins:
```powershell
ollama rm llama3.2:3b
```

## D. Direkt eine Frage ohne Chat-Modus

```powershell
ollama run qwen2.5:7b "Schreibe mir 3 Bullet-Points zu Photosynthese"
```
Antwort kommt, Ollama beendet sich wieder.

## E. Aus Skripten nutzen — Ollama als „API"

Ollama hoert auf `http://localhost:11434`. In PowerShell:

```powershell
$body = @{
    model  = 'qwen2.5:7b'
    prompt = 'Klassifiziere diese Mail: Ihre Rechnung ueber 49 EUR'
    stream = $false
} | ConvertTo-Json

(Invoke-RestMethod -Method Post -Uri http://localhost:11434/api/generate -Body $body -ContentType 'application/json').response
```
Was passiert: Ollama schickt die Antwort als Text zurueck.

In Python (z.B. fuer dein `classify.py`):
```python
import requests
r = requests.post('http://localhost:11434/api/generate',
    json={'model':'qwen2.5:7b','prompt':'Klassifiziere: ...','stream':False})
print(r.json()['response'])
```

## F. Mit eigenem System-Prompt (Persona)

Datei `Modelfile` schreiben:
```
FROM qwen2.5:7b
SYSTEM "Du bist ein praeziser Brief-Klassifizierer. Antworte nur mit JSON: {kategorie, prioritaet}."
PARAMETER temperature 0.1
```

Dann:
```powershell
ollama create brief-bot -f Modelfile
ollama run brief-bot
```
Jetzt ist `brief-bot` ein eigenes Modell mit deiner Persona — kannst du immer wieder aufrufen.

## G. Wenn was nicht laeuft

- **„command not found"** → PowerShell schliessen + neu oeffnen (Pfad neu laden).
- **„connection refused" auf 11434** → `ollama serve` in einer extra PowerShell starten.
- **Antwort dauert ewig** → kleineres Modell nehmen (`llama3.2:3b`).
- **Speicher voll** → `ollama list` ansehen, mit `ollama rm <name>` aufraeumen. Modelle liegen in `C:\Users\<du>\.ollama\models`.

## H. Dein Ask-Fenster verstehen

`C:\Users\Admin\Ask` enthaelt vermutlich ein kleines WPF/AHK-Fenster, das genau so eine `Invoke-RestMethod`- oder Python-Anfrage an `localhost:11434` schickt. Wenn du das Modell wechseln willst: in der Konfig-Datei `qwen2.5:7b` durch deinen Wunschnamen ersetzen.

---

# VS CODE — Tutorial-Sektion

> VS Code ist ein **Datei-Editor mit Power-Features**. Anders als Notepad sieht es Farben, hat ein eingebautes Terminal und kann mit Git umgehen. Du musst es nicht im Alltag nutzen — aber wenn du mal Code anfasst, ist es viel angenehmer.

## A. Installation

```powershell
winget install Microsoft.VisualStudioCode
```
Oder: `setup\1-pc\dev-setup.ps1` haengt es eh dran.
Nach Installation: `code` im Terminal — VS Code geht auf. Oder ueber Startmenue.

## B. Was siehst du beim ersten Start

```
+---------+------------------+----------+
| Sidebar |    Editor        |  Mini    |
| (links) |  (Mitte, gross)  |  (rechts)|
+---------+------------------+----------+
| Statusleiste unten                     |
+----------------------------------------+
```
- **Linke Spalte (Sidebar)**: Datei-Liste, Suche, Git-Status, Plugins.
- **Mitte (Editor)**: hier bearbeitest du Dateien. Mehrere Tabs nebeneinander moeglich.
- **Rechts (Minimap)**: Mini-Vorschau der Datei.
- **Unten (Statusleiste)**: Branch, Encoding, Sprache.

## C. Die 5 Tasten, die du brauchst

| Hotkey                 | Was es macht                                                     |
|------------------------|------------------------------------------------------------------|
| `F1` oder `Strg+Shift+P` | **Befehlspalette** — alles lebt hier drin. Tippe was du willst, z.B. „format", „run", „terminal". |
| `Strg+P`               | Datei aus dem Projekt schnell oeffnen — tippe Anfang vom Namen. |
| `Strg+B`               | linke Sidebar ein/aus                                            |
| `Strg+ö`               | Terminal unten ein/aus (auf deutscher Tastatur die Taste neben Enter) |
| `Strg+Shift+F`         | Volltextsuche im ganzen Projekt                                  |

## D. Eine Datei oeffnen + bearbeiten — Schritt fuer Schritt

1. VS Code starten.
2. Oben links: **„File" → „Open Folder…"** → den Ordner waehlen, in dem dein Projekt liegt (z.B. `C:\Users\Admin\Briefe\Bin`).
3. Links siehst du die Datei-Liste — Klick auf z.B. `classify.py`.
4. Tippen, speichern mit `Strg+S`. Fertig — Datei ist gespeichert.

## E. Ein PowerShell-Skript in VS Code laufen lassen

1. Datei `hallo.ps1` neu anlegen (`Strg+N`, dann `Strg+S` mit Endung `.ps1`).
2. Reinschreiben:
   ```powershell
   Write-Host 'Hallo Welt'
   ```
3. Terminal aufmachen: `Strg+ö`. Du landest in einem PowerShell-Fenster **innerhalb** von VS Code.
4. Tippen:
   ```powershell
   .\hallo.ps1
   ```
5. Output erscheint im Terminal. Falls Meldung wegen ExecutionPolicy:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\hallo.ps1
   ```

## F. Ein Python-Skript laufen lassen

1. Datei `test.py`:
   ```python
   print("Hallo")
   ```
2. Terminal:
   ```powershell
   python test.py
   ```
3. Wenn Python fehlt: `winget install Python.Python.3.12`.

## G. Plugins (Extensions) — was sich lohnt

Sidebar links → 4-Quader-Icon → suchen + installieren:
- **Python** (von Microsoft) — wenn du `.py` anfasst
- **PowerShell** (von Microsoft) — Syntax-Farben + Hover-Hilfe
- **GitLens** — Git-Geschichte direkt in der Datei
- **Markdown All in One** — schoene Vorschau mit `Strg+Shift+V`

## H. Wann VS Code, wann nicht

- **Notepad**: schnelle Textnotiz, eine Zeile aendern.
- **PowerShell direkt**: ein Befehl, kein Editieren noetig.
- **VS Code**: mehrere Dateien, Ordnerstruktur, Suchen ueber alles, Git-Status.
