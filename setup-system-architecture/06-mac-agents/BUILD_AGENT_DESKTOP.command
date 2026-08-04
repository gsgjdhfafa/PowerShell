#!/bin/bash
# ============================================================
#  BUILD AGENT DESKTOP  -  baut ~/Desktop/AGENTS/ aus echten Scan-Daten
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/BUILD_AGENT_DESKTOP.command
#  Erstellt nur Ordner/Dateien unter ~/Desktop/AGENTS/, aendert
#  nichts an Ollama/OpenClaw selbst. Idempotent (ueberschreibt nur
#  die eigenen Start-Skripte, keine fremden Daten).
#
#  Basiert auf MAC_AGENT_SCAN.command Ergebnis vom 04.08.2026:
#  Apple M3 Pro, 18 GB RAM, 11 Ollama-Modelle, OpenClaw unter ~/.openclaw
# ============================================================
set -uo pipefail
echo "============================================================"
echo "  BUILD AGENT DESKTOP"
echo "============================================================"

ROOT="$HOME/Desktop/AGENTS"
MODELS="$ROOT/01_MODELLE"
OC="$ROOT/02_OPENCLAW"
MEM="$ROOT/03_MEMORY_PFADE"
mkdir -p "$MODELS" "$OC" "$MEM"

mk_start () { # $1=dateiname $2=modell $3=hinweis
  cat > "$MODELS/$1" <<EOF
#!/bin/bash
echo "Starte $2 ..."
echo "($3)"
echo "Beenden mit /bye oder Strg+C."
echo
ollama run "$2"
EOF
  chmod +x "$MODELS/$1"
}

# --- Empfohlen (laufen komfortabel bei 18 GB RAM) ---------------
mk_start "Start_llama3.2-3b.command"     "llama3.2:3b"     "2.0 GB - sehr schnell, gut fuer schnelle Antworten"
mk_start "Start_phi3.5-3.8b.command"     "phi3.5:3.8b"     "2.2 GB - sehr schnell"
mk_start "Start_phi4-mini.command"       "phi4-mini"       "2.5 GB - sehr schnell"
mk_start "Start_qwen2.5-7b.command"      "qwen2.5:7b"      "4.7 GB - gute Allround-Qualitaet"
mk_start "Start_deepseek-r1-7b.command"  "deepseek-r1:7b"  "4.7 GB - staerker im Denken/Reasoning, etwas langsamer"
mk_start "Start_llama3.1-8b.command"     "llama3.1:8b"     "4.9 GB - solide Allround-Wahl"
mk_start "Start_gemma2-9b.command"       "gemma2:9b"       "5.4 GB - gut, noch komfortabel"
mk_start "Start_mistral-nemo-12b.command" "mistral-nemo:12b" "7.1 GB - macht, aber spuerbar langsamer"

# --- Grenzwertig bei 18 GB RAM - mit Warnhinweis -----------------
cat > "$MODELS/Start_codestral_VORSICHT.command" <<'EOF'
#!/bin/bash
echo "============================================================"
echo "  codestral (12 GB) - VORSICHT bei 18 GB Gesamt-RAM"
echo "  Kann spuerbar langsam sein oder swappen, macOS + andere"
echo "  Apps brauchen auch RAM. Staerkstes Modell hier fuer Code."
echo "============================================================"
read -r -p "Trotzdem starten? [j/N] " a
case "$a" in j|J|ja|Ja) ;; *) echo "Abgebrochen."; exit 0 ;; esac
ollama run codestral
EOF
chmod +x "$MODELS/Start_codestral_VORSICHT.command"

cat > "$MODELS/EMPFEHLUNG.md" <<'EOF'
# Modell-Empfehlung fuer dieses Geraet (Apple M3 Pro, 18 GB RAM)

Faustregel: Modell-Groesse + ca. 4-6 GB Puffer fuer macOS/Apps sollte
unter 18 GB bleiben, sonst wird es langsam (Swap).

| Modell | Groesse | Einschaetzung |
|---|---|---|
| llama3.2:3b | 2.0 GB | sehr schnell, fuer schnelle/simple Aufgaben |
| phi3.5:3.8b | 2.2 GB | sehr schnell |
| phi4-mini | 2.5 GB | sehr schnell |
| qwen2.5:7b | 4.7 GB | gute Allround-Qualitaet |
| deepseek-r1:7b | 4.7 GB | staerker im Reasoning |
| llama3.1:8b | 4.9 GB | solide Allround-Wahl |
| gemma2:9b | 5.4 GB | gut, noch komfortabel |
| mistral-nemo:12b | 7.1 GB | macht, spuerbar langsamer |
| codestral | 12 GB | grenzwertig - staerkstes Code-Modell, aber Vorsicht |
| nomic-embed-text | 274 MB | Embedding-Modell, kein Chat (fuer RAG/Suche) |
| bge-m3 | 1.2 GB | Embedding-Modell, kein Chat (fuer RAG/Suche) |

Die zwei Embedding-Modelle haben keine eigenen Start-Icons - die
werden programmatisch genutzt (z.B. von RAG-Systemen), nicht
interaktiv gestartet.
EOF

echo "[OK] $MODELS erstellt (9 Start-Icons + Empfehlung)"

# --- OpenClaw ------------------------------------------------
# "5 Definitionsdateien" = die 5 nicht-Backup-Kerndateien aus dem Scan:
#   openclaw.json, workspace-state.json, gateway.env, gateway-env-wrapper.sh, state.sqlite
# (alle .bak*/.last-good/tmp bewusst ausgelassen - reine Sicherungen/Muell)

cat > "$OC/Start_OpenClaw_Panel.command" <<'EOF'
#!/bin/bash
bash "$HOME/bin/openclaw-panel.sh"
EOF
chmod +x "$OC/Start_OpenClaw_Panel.command"

cat > "$OC/OpenRouter_hinzufuegen.command" <<'EOF'
#!/bin/bash
bash "$HOME/bin/openclaw-add-openrouter.sh"
EOF
chmod +x "$OC/OpenRouter_hinzufuegen.command"

cat > "$OC/Remote_Hetzner.command" <<'EOF'
#!/bin/bash
bash "$HOME/bin/openclaw-remote-hetzner.sh"
EOF
chmod +x "$OC/Remote_Hetzner.command"

cat > "$OC/Oeffne_Config.command" <<'EOF'
#!/bin/bash
open -R "$HOME/.openclaw/openclaw.json"
EOF
chmod +x "$OC/Oeffne_Config.command"

cat > "$OC/Oeffne_Workspace.command" <<'EOF'
#!/bin/bash
open -R "$HOME/.openclaw/workspace/openclaw-workspace-state.json"
EOF
chmod +x "$OC/Oeffne_Workspace.command"

cat > "$OC/Oeffne_GatewayEnv.command" <<'EOF'
#!/bin/bash
open -R "$HOME/.openclaw/service-env/ai.openclaw.gateway.env"
EOF
chmod +x "$OC/Oeffne_GatewayEnv.command"

cat > "$OC/Oeffne_State_DB.command" <<'EOF'
#!/bin/bash
open -R "$HOME/.openclaw/state/openclaw.sqlite"
EOF
chmod +x "$OC/Oeffne_State_DB.command"

cat > "$OC/README.md" <<'EOF'
# OpenClaw - Kern-Dateien

Aus dem Scan vom 04.08.2026 identifiziert (nur Kern, keine Backups):

| Datei | Zweck |
|---|---|
| `~/.openclaw/openclaw.json` | Hauptkonfiguration |
| `~/.openclaw/workspace/openclaw-workspace-state.json` | Workspace-Zustand |
| `~/.openclaw/service-env/ai.openclaw.gateway.env` | Gateway-Umgebungsvariablen |
| `~/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh` | Gateway-Wrapper-Skript |
| `~/.openclaw/state/openclaw.sqlite` | Zustands-Datenbank |

Ausgelassen (bewusst kein Shortcut): alle `openclaw.json.bak*`,
`.last-good`, `tmp/` - das sind Sicherungen/Muell, keine aktiven
Definitionsdateien.

Falls diese 5 nicht das waren, was gemeint war - bitte konkretisieren,
dann passe ich die Shortcuts an.

## Skripte (aus ~/bin/)

- `Start_OpenClaw_Panel.command` -> `openclaw-panel.sh`
- `OpenRouter_hinzufuegen.command` -> `openclaw-add-openrouter.sh`
- `Remote_Hetzner.command` -> `openclaw-remote-hetzner.sh`
EOF

echo "[OK] $OC erstellt (3 Start-Skripte + 4 Datei-Shortcuts + README)"

# --- Memory-Pfade (Symlinks) --------------------------------------
ln -sfn "$HOME/.ollama" "$MEM/Ollama_Modelle_und_Daten"
ln -sfn "$HOME/.openclaw" "$MEM/OpenClaw_Zustand_und_Konfig"
echo "[OK] $MEM erstellt (2 Symlinks zu Ollama + OpenClaw)"

cat > "$ROOT/README.md" <<'EOF'
# AGENTS

Erstellt von BUILD_AGENT_DESKTOP.command am 04.08.2026,
basierend auf dem echten MAC_AGENT_SCAN.command Ergebnis.

- `01_MODELLE/` - Doppelklick-Start fuer jedes lokale Ollama-Modell,
  plus EMPFEHLUNG.md zur RAM-Einschaetzung (M3 Pro, 18 GB)
- `02_OPENCLAW/` - Start-Skripte + Shortcuts zu den 5 Kern-Dateien
- `03_MEMORY_PFADE/` - Symlinks zu den Daten-/Zustandsordnern

Alles hier sind Skripte/Symlinks, keine Kopien der echten Daten -
loeschen dieses Ordners aendert nichts an Ollama/OpenClaw selbst.
EOF

echo
echo "============================================================"
echo "  FERTIG: $ROOT"
echo "============================================================"
open "$ROOT"
read -r -p "[Enter] zum Schliessen "
