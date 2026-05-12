#!/usr/bin/env bash
# In Ubuntu-WSL ausfuehren. Installiert Ollama + Hermes Agent + OpenCode.
# Idempotent.
# Aufruf:  bash install-agents-in-wsl.sh
set -euo pipefail

echo '== zf agents installer (WSL/Linux) =='

# --- 1. Basis -----------------------------------------------------------------
sudo apt-get update -y
sudo apt-get install -y curl git build-essential ca-certificates

# --- 2. Node.js 20 (fuer Claude Code + OpenCode + viele Agents) --------------
if ! command -v node >/dev/null 2>&1 || ! node -v | grep -qE '^v(20|22)'; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo "[ok] node $(node -v), npm $(npm -v)"

# --- 3. Ollama in WSL --------------------------------------------------------
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh
fi
# Ollama-Daemon im Hintergrund starten falls noch nicht laeuft.
if ! pgrep -x ollama >/dev/null; then
    nohup ollama serve >/tmp/ollama.log 2>&1 &
    sleep 2
fi
echo "[ok] $(ollama --version 2>&1 | head -n1)"

# --- 4. Claude Code (Anthropic CLI) ------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
    sudo npm install -g @anthropic-ai/claude-code
fi
echo "[ok] claude $(claude --version 2>/dev/null || echo 'installiert')"

# --- 5. OpenCode -------------------------------------------------------------
# Anomaly OpenCode: aktuell via Bash-Installer (siehe opencode.ai).
if ! command -v opencode >/dev/null 2>&1; then
    curl -fsSL https://opencode.ai/install | bash || \
        echo '[warn] OpenCode-Installer fehlgeschlagen. Manuell von https://opencode.ai nachholen.'
fi
command -v opencode >/dev/null 2>&1 && echo "[ok] opencode $(opencode --version 2>/dev/null || echo 'installiert')" || true

# --- 6. Codex CLI (OpenAI) ---------------------------------------------------
if ! command -v codex >/dev/null 2>&1; then
    sudo npm install -g @openai/codex
fi
echo "[ok] codex $(codex --version 2>/dev/null || echo 'installiert')"

# --- 7. Hermes Agent ueber Ollama-Launcher -----------------------------------
# Hermes wird ueber `ollama launch hermes` initialisiert. Wir starten den
# Launcher kurz, damit die Agent-Liste sich zieht — der eigentliche `launch`
# muss interaktiv erfolgen, daher zeigen wir nur den Hinweis.
echo
echo '------------------------------------------------------------------'
echo 'Hermes Agent installieren (interaktiv):'
echo '   ollama launch hermes'
echo
echo 'Weitere Agenten ueber den Ollama-Launcher:'
echo '   ollama'
echo '   -> Pfeiltasten + Enter ueber das Menue.'
echo '------------------------------------------------------------------'

# --- 8. Sanity: ein kleines Modell ziehen damit Ollama bereit ist ------------
ollama pull llama3.2:3b || true
echo "[ok] llama3.2:3b verfuegbar"

echo
echo '[done] agents installer fertig.'
echo
echo 'Quick test:'
echo '   ollama list                     # zeigt installierte Modelle'
echo '   ollama run llama3.2:3b hi       # einmal kurz checken'
echo '   claude /login                   # Anthropic login'
echo '   codex                           # OpenAI Codex login'
echo '   ollama launch hermes            # Hermes-Setup'
