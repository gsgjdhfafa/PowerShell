#!/bin/bash
# ============================================================
#  BUILD CONTROL PANEL  -  zentraler Hub + Doku auf dem Schreibtisch
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/BUILD_CONTROL_PANEL.command
#  Baut ~/Desktop/CONTROL_PANEL/ mit Shortcuts zu allem, was bisher
#  aufgebaut wurde (Pico, lokale Agenten, OpenClaw, Raspberry Pi,
#  Bot-Deploy) + einer zusammenfassenden Doku. Reine Skripte/Links,
#  keine Kopien echter Daten. Idempotent.
# ============================================================
set -uo pipefail
echo "============================================================"
echo "  BUILD CONTROL PANEL"
echo "============================================================"

CP="$HOME/Desktop/CONTROL_PANEL"
mkdir -p "$CP"

BRANCH_URL="https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-XKISu/setup-system-architecture"

mk () { # $1=dateiname  $2...=inhalt (heredoc via stdin)
  cat > "$CP/$1"
  chmod +x "$CP/$1"
}

# --- PICO -----------------------------------------------------
mk "1_PICO_Status_Scan.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/PICO_AUDIT_MAC.command "$BRANCH_URL/05-vr/pico-control-center/PICO_AUDIT_MAC.command" && bash /tmp/PICO_AUDIT_MAC.command
EOF

mk "1_PICO_Nach_Reset_Wiederherstellen.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/PICO_REBUILD_ALL.command "$BRANCH_URL/05-vr/pico-rebuild/PICO_REBUILD_ALL.command" && bash /tmp/PICO_REBUILD_ALL.command
EOF

mk "1_PICO_Connect_starten.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/PICO_CONNECT_MAC.command "$BRANCH_URL/05-vr/pico-rebuild/PICO_CONNECT_MAC.command" && bash /tmp/PICO_CONNECT_MAC.command
EOF

mk "1_PICO_Vollmenue.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/PICO_CONTROL_CENTER.py "$BRANCH_URL/05-vr/pico-control-center/PICO_CONTROL_CENTER.py" && python3 /tmp/PICO_CONTROL_CENTER.py
EOF

# --- Lokale Agenten / OpenClaw ----------------------------------
mk "2_Lokale_Modelle_Ordner_oeffnen.command" <<'EOF'
#!/bin/bash
open "$HOME/Desktop/AGENTS"
EOF

mk "2_OpenClaw_Panel.command" <<'EOF'
#!/bin/bash
bash "$HOME/bin/openclaw-panel.sh"
EOF

# --- Raspberry Pi -------------------------------------------------
mk "3_Raspberry_Pi_SSH.command" <<'EOF'
#!/bin/bash
if grep -q "^Host raspi$" "$HOME/.ssh/config" 2>/dev/null; then
  ssh raspi
else
  echo "SSH noch nicht eingerichtet. Erst ausfuehren:"
  echo "  bash ~/Desktop/PI_SSH_SETUP.command"
  read -r -p "[Enter] "
fi
EOF

mk "3_Raspberry_Pi_SSH_einrichten.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/PI_SSH_SETUP.command "$BRANCH_URL/07-raspberry-pi/PI_SSH_SETUP.command" && bash /tmp/PI_SSH_SETUP.command
EOF

# --- Bot-Deploy -----------------------------------------------
mk "4_Bot_Deploy_Links_ansehen.command" <<EOF
#!/bin/bash
curl -fsSL -o /tmp/DEPLOY_LINKS.md "$BRANCH_URL/03-bot/DEPLOY_LINKS.md" && open /tmp/DEPLOY_LINKS.md
EOF

# --- Master-Doku -------------------------------------------------
cat > "$CP/DOKUMENTATION.md" <<'EOF'
# CONTROL PANEL — Übersicht (Stand 04.08.2026)

Alle Icons in diesem Ordner laden das jeweils aktuelle Skript direkt
vom Repo und führen es aus — sie sind schlanke Aufrufer, keine Kopien.
Quelle: `gsgjdhfafa/PowerShell`, Branch `claude/setup-system-architecture-XKISu`.

## 1 — PICO 4 Ultra

| Icon | Macht was |
|---|---|
| `1_PICO_Status_Scan` | Zeigt: Ziel-Apps da/fehlend, Freeze-Kandidaten, bereits Eingefrorenes |
| `1_PICO_Nach_Reset_Wiederherstellen` | Kompletter Wiederaufbau nach Werksreset (Apps + Freeze-Liste) |
| `1_PICO_Connect_starten` | Startet PICO Connect (Multi-Monitor-Streaming, **1 PC gleichzeitig**) |
| `1_PICO_Vollmenue` | Interaktives Python-Menü: alle 20 Funktionen |

**Aktueller Stand:** 4/4 Ziel-Apps (Telegram, Brave, VLC, Wolvic) installiert,
13 Apps eingefroren (reversibel), Telegram angemeldet.

**Wichtig zu PICO Connect:** koppelt sich mit **einem** PC gleichzeitig
(bis zu 3 virtuelle Monitore von diesem PC). Kein bekannter/dokumentierter
Weg, mehrere PCs gleichzeitig in einer Session anzuzeigen.

## 2 — Lokale Agenten (Ollama + OpenClaw)

| Icon | Macht was |
|---|---|
| `2_Lokale_Modelle_Ordner_oeffnen` | Öffnet `~/Desktop/AGENTS/` (9 Modell-Start-Icons, RAM-sortiert) |
| `2_OpenClaw_Panel` | Startet dein OpenClaw-Panel (`~/bin/openclaw-panel.sh`) |

**Hardware:** Apple M3 Pro, 18 GB RAM. Empfohlene Modelle bis ~9 GB
(llama3.2, phi3.5, phi4-mini, qwen2.5, deepseek-r1, llama3.1, gemma2).
`mistral-nemo` macht, `codestral` (12 GB) ist grenzwertig.

## 3 — Raspberry Pi

| Icon | Macht was |
|---|---|
| `3_Raspberry_Pi_SSH_einrichten` | Einmalig: findet den Pi, richtet SSH-Key + `~/.ssh/config` ein |
| `3_Raspberry_Pi_SSH` | Danach: direkter SSH-Login (Alias `raspi`) |

Nach der Einrichtung reicht im Terminal auch einfach: `ssh raspi`

## 4 — Telegram-Bot-Deploy

| Icon | Macht was |
|---|---|
| `4_Bot_Deploy_Links_ansehen` | Checkliste: BotFather, Notion, Anthropic/OpenAI-Keys |

Danach auf dem VPS: `sudo bash setup-system-architecture/03-bot/SETUP_BOT_WIZARD.sh`

## Repo-Struktur (zur Orientierung)

```
01-pc/              Windows/Mac PC-Grundsetup
02-server/           VPS Base + Docker + Härtung
03-bot/               Telegram-Bot + Deploy-Wizard
04-integration/       KI + Notion Anbindung
05-vr/                PICO 4 Ultra (Control Center, Rebuild, Nutzung)
06-mac-agents/        Lokale Modelle + OpenClaw Discovery/Build
07-raspberry-pi/      SSH-Einrichtung für den Pi
08-control-panel/     Dieser Ordner-Generator
```

## Alles neu aufbauen (frischer Mac / nach Reset)

```bash
curl -fsSL -o ~/Desktop/BUILD_CONTROL_PANEL.command "https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-XKISu/setup-system-architecture/08-control-panel/BUILD_CONTROL_PANEL.command" && chmod +x ~/Desktop/BUILD_CONTROL_PANEL.command && bash ~/Desktop/BUILD_CONTROL_PANEL.command
```
EOF

echo "[OK] $CP erstellt (9 Icons + DOKUMENTATION.md)"
echo
open "$CP"
read -r -p "[Enter] zum Schliessen "
