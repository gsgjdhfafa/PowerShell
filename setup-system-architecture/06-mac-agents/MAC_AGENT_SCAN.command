#!/bin/bash
# ============================================================
#  MAC AGENT SCAN  -  was laeuft lokal, wo liegt OpenClaw?
# ============================================================
#  Nutzung: Doppelklick im Finder, oder im Terminal:
#     bash ~/Desktop/MAC_AGENT_SCAN.command
#  Reiner Scan (lesend). Aendert nichts.
#
#  Zweck: bevor wir Ordner mit Start-Icons pro Modell und
#  Shortcuts zu Memory-Pfaden bauen, muessen wir wissen, was
#  wirklich installiert ist und wo es liegt - sonst zeigen die
#  Shortcuts ins Leere. Ergebnis bitte in den Chat zurueckgeben.
# ============================================================
echo "============================================================"
echo "  MAC AGENT SCAN"
echo "============================================================"

echo
echo "--- Hardware (fuer 'was laeuft gut hier') ---"
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
[ -z "$CHIP" ] && CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip/{print $2}')
RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
RAM_GB=$(( RAM_BYTES / 1024 / 1024 / 1024 ))
echo "  Chip: ${CHIP:-unbekannt}"
echo "  RAM:  ${RAM_GB} GB"
echo "  macOS: $(sw_vers -productVersion 2>/dev/null)"

echo
echo "--- Ollama ---"
if command -v ollama >/dev/null 2>&1; then
  echo "  [OK] installiert: $(command -v ollama)"
  echo "  Modelle:"
  ollama list 2>/dev/null | sed 's/^/    /'
else
  echo "  [-] nicht gefunden"
fi

echo
echo "--- LM Studio ---"
if [ -d "/Applications/LM Studio.app" ]; then
  echo "  [OK] App: /Applications/LM Studio.app"
else
  echo "  [-] App nicht gefunden"
fi
LMS_DIR="$HOME/.cache/lm-studio/models"
if [ -d "$LMS_DIR" ]; then
  echo "  Modelle-Ordner: $LMS_DIR"
  find "$LMS_DIR" -maxdepth 3 -iname "*.gguf" 2>/dev/null | sed 's/^/    /' | head -20
else
  echo "  [-] Modelle-Ordner nicht gefunden ($LMS_DIR)"
fi

echo
echo "--- GPT4All ---"
if [ -d "/Applications/gpt4all.app" ] || [ -d "$HOME/Library/Application Support/nomic.ai" ]; then
  echo "  [OK] Hinweise auf GPT4All gefunden"
else
  echo "  [-] nicht gefunden"
fi

echo
echo "--- llama.cpp / koboldcpp (CLI-Runtimes) ---"
for bin in llama-cli llama-server main koboldcpp koboldcpp.py; do
  command -v "$bin" >/dev/null 2>&1 && echo "  [OK] $bin: $(command -v "$bin")"
done

echo
echo "--- Homebrew-installierte KI-Tools (grobe Liste) ---"
if command -v brew >/dev/null 2>&1; then
  brew list 2>/dev/null | grep -iE 'ollama|llama|whisper|langchain|mlx|torch|transformers' | sed 's/^/    /'
else
  echo "  [-] Homebrew nicht gefunden"
fi

echo
echo "--- OpenClaw ---"
FOUND_OC=0
for cand in "$HOME/openclaw" "$HOME/.openclaw" "$HOME/bin" "$HOME/Projects" "$HOME/Documents"; do
  if [ -d "$cand" ]; then
    HITS=$(find "$cand" -maxdepth 3 -iname "*openclaw*" 2>/dev/null)
    if [ -n "$HITS" ]; then
      FOUND_OC=1
      echo "  Treffer unter $cand:"
      echo "$HITS" | sed 's/^/    /'
    fi
  fi
done
if [ "$FOUND_OC" -eq 0 ]; then
  echo "  [-] Nichts unter ~/openclaw, ~/.openclaw, ~/bin, ~/Projects, ~/Documents gefunden."
  echo "      Falls es woanders liegt: Pfad bitte direkt mitteilen, dann bauen wir"
  echo "      die Shortcuts gezielt statt blind zu suchen."
fi

echo
echo "============================================================"
echo "  FERTIG. Bitte die komplette Ausgabe zurueck in den Chat kopieren -"
echo "  darauf aufbauend baue ich Ordner mit Start-Icons pro Modell +"
echo "  Shortcuts zu den jeweiligen Memory-Pfaden."
echo "============================================================"
read -r -p "[Enter] zum Schliessen "
