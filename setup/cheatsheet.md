# Workspace Cheatsheet

Live-Referenz aus deinen beiden Wallpaper-Cards (Workspace + KI-Tools).

## HOTKEYS (F-Keys + Media)

| Shortcut          | Funktion                                  |
|-------------------|-------------------------------------------|
| `Shift+F1`        | Mail Gerrit (Master)                      |
| `Shift+F2`        | Mail TTT (Taucher)                        |
| `Shift+F3`        | Mail Comet TTT-Pro                        |
| `Shift+F4`        | Kalender Gerrit                           |
| `Shift+F6`        | Kalender TTT                              |
| `Shift+F7`        | Drive Gerrit                              |
| `Shift+F8`        | Drive TTT                                 |
| `Shift+F9`        | NotebookLM                                |
| `Shift+F10`       | Asana                                     |
| `Shift+F11`       | ASKGENT                                   |
| `Shift+Strg+F3`   | 3x Comet TTT-Pro                          |
| `Strg+V`          | PASTE                                     |
| `Strg+C`          | COPY                                      |
| `Strg+X`          | CUT                                       |
| `Ctrl+Shift+Tab`  | Tab links                                 |
| `Ctrl+Tab`        | Tab rechts                                |
| `Vol +/-` / `Mute`| Lautstaerke                               |
| `Skip <- / ->`    | Skip                                      |

## SOT — Top-Pfade

| Bereich         | Pfad                                                     |
|-----------------|----------------------------------------------------------|
| Briefe-Triage   | `C:\Users\Admin\Briefe`  (Inbox / Pending / Processing / Done) |
| Briefe-Bin      | `C:\Users\Admin\Briefe\Bin`  (`classify.py` / `diagnose.py`)   |
| Triton CC       | `C:\Users\Admin\Dashboard`  (HttpListener `:7777`)             |
| CC-Module       | `C:\Users\Admin\Dashboard\modules`  (`start-*.ps1`)            |
| Wallpapers      | `C:\Users\Admin\Wallpapers`  (generate + apply Span)           |
| Notes daemon    | `C:\Users\Admin\Notes`  (AHK Sticky-Notes `Win+N`)             |
| Task Scanner    | `C:\Users\Admin\TaskScanner`  (WPF Always-on-Top)              |
| Ask Window      | `C:\Users\Admin\Ask`  (qwen2.5:7b lokal)                       |
| Account-AHK     | `C:\Users\Admin\account-shortcuts.ahk`  (alle Hotkeys)         |
| Watcher-AHK     | `C:\Users\Admin\watcher-shortcuts.ahk`  (`Win+Alt+T/D/G`)      |

## Goldene Regeln

- **Drive-Sammelordner**: nie Original verschieben — NUR Kopien in Aggregations-Ordner.
- **Chrome ohne Profil**: NIE — jedes Chrome-Fenster hat `--profile-directory=…`.
- **Comet Default = TTT**: Default-Profil (Neptun) = TTT-Pro Premium — bis Override.
- **Fenster-Position**: IMMER auf Cursor-Monitor oeffnen, nicht Primary.
- **1 Profil = 1 Fenster**: Tabs sammeln sich im Profil-Fenster, kein `--new-window`.
- **Briefe Triage**: OCR + Klassifizierer + Mensch entscheidet — KEIN Auto-Send/Pay.
- **Memory ist SOT**: `MEMORY.md` = Index, einzelne `.md` = Quellen, nie duplizieren.
- **Kein VS / VS Code**: User kann es nicht — Notepad / Browser / PowerShell als Alternative.
- **Scope dieses Chats**: NUR PC-Optimierung — Triton-Inhalte / Recht in eigenen Chats.
- **3-Desktop-Modell**: D1=Monitoring | D2=Projects (1 Task) | D3=Dev/Sandbox.
- **Triton CC fokus**: Workspace re-snap — kein Drift.

## Pipeline TOP-4

| # | Stufe       | Inhalt                                                                       |
|---|-------------|------------------------------------------------------------------------------|
| 1 | PITCH       | Pitch + Business-Plan + Anhang + TV-Aus + Know-how (KI4KI)                  |
| 2 | BEWERBUNG   | Programm-Calls KI4KI + Taucherteam Triton GmbH                               |
| 3 | INSOLVENZ   | Widerspruch einlegen, Fristen maximal verlaengern — fristengetrieben         |
| 4 | BETREUUNG   | Vorfall melden Jugendamt + Termin + Oberlandesgericht — fristengetrieben     |

## Workflows TOP-5

| Workflow         | Ablauf                                                                    |
|------------------|---------------------------------------------------------------------------|
| Briefe-Pipeline  | Scan -> OCR -> Ollama Klassifizierer -> Triage -> Inbox/Pending/Done      |
| Tasks-Pipeline   | `Pipeline.md` (Top-4) -> Asana (operativ) -> Wo arbeitet welcher Chat?    |
| Knowledge        | NotebookLM Master (6 Books, ~235 Sources) -> `Shift+F9`                   |
| Mail-Triage      | Mail Gerrit/TTT/Comet -> Briefe-Triage -> Antwort/Archiv                  |
| Code-Workflow    | PowerShell direkt | AHK Skripte | Python (`Briefe\Bin`) | KEIN VS Code   |

---

# KI-Tools Referenz

## OpenAI ChatGPT
- **URL**:  `chatgpt.com` | `chat.openai.com`
- **Models**: GPT-4o (multimodal) | GPT-4.5 | o1/o3 (reasoning) | gpt-image-1
- **Hotkeys**: `Strg+Enter` Send | `Strg+Shift+O` Neuer Chat | `Strg+/` Fokus Input
- **Features**: Memory | Custom Instructions | Projects | Canvas | Voice
- **Cost**: Plus $20/m | Team $25/usr | Pro $200/m (o1-pro)

## Anthropic Claude
- **URL**: `claude.ai` | `console.anthropic.com`
- **Models**: Sonnet 4.6 (default) | Opus 4.6 (deep) | Haiku 4.5 (schnell)
- **Apps**: Claude Desktop (MSIX) | Claude Code CLI | claude.ai web
- **Hotkeys**: `Strg+Enter` Send | `Strg+K` Neuer Chat | `Strg+/` Cmd-Palette
- **Features**: Projects | Artifacts | Computer-Use | Memory (Auto)

## Google Gemini + NotebookLM
- `gemini.google.com` — 2M Context, multimodal
- `aistudio.google.com` — API + System-Prompt-Tuning
- `notebooklm.google.com` — Sources -> Q&A (in COMET!)
- **Models**: Gemini 2.5 Pro/Flash | Gemma3 (lokal) | Imagen 4
- **Hotkeys**: `Strg+Enter` Send | `/` im Input = Slash-Cmds

## Perplexity Comet (Browser)
- **App**: `C:\Program Files\Perplexity\Comet\Application\comet.exe`
- **Profile**: Default = Neptun (TTT-Pro) | Profile1 = Gerrit (KI4KI)
- **Sidebar**: Sidekick (`Alt+L`) | Tasks-Panel | Tab-Assistant
- **Pro**: Comet-Assistant in jedem Tab | Web-Aktionen | Spaces
- **Hotkeys**: `Strg+T` Tab | `Strg+Shift+L` Sidekick | `Strg+J` Tasks

## Perplexity (Web)
- **URL**: `perplexity.ai` | `pplx.ai`
- **Models**: Sonar | Claude | GPT-4 | Grok per Auswahl
- **Spaces**: Themen-Container mit Custom Prompts + Files
- **Pro**: $20/m | Sonar API | Image-Gen
- **Hotkeys**: `Strg+Shift+P` Pro | `Strg+I` Image-Mode

## Cursor IDE
- **URL**: `cursor.com` — Fork von VS Code mit AI
- **Hotkeys**: `Strg+K` Inline-Edit | `Strg+L` Chat | `Strg+I` Composer
- **Models**: Claude Sonnet/Opus | GPT-4o | o1
- **Features**: `.cursorrules` | Tab-Autocomplete | Codebase
- **Cost**: Hobby Free | Pro $20/m

## VS Code (Notfall — User kann nicht)
- `F1` Cmd-Palette | `Strg+B` Sidebar | `Strg+J` Terminal | `Strg+P` Datei | `Strg+Shift+F` Volltext-Suche
