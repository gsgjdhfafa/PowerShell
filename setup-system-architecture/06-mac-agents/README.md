# 06-mac-agents

Ordner mit Start-Icons pro lokalem Modell/Agent + Shortcuts zu den
jeweiligen Memory-/Config-Pfaden + OpenClaw-Organisation.

**Noch nicht gebaut** — dafuer muss erst bekannt sein, was auf dem
Mac tatsaechlich installiert ist (Hardware-Grenzen, welche lokalen
Modelle/Runtimes vorhanden sind, wo OpenClaw mit seinen 5
Definitionsdateien liegt). Blind Shortcuts auf vermutete Pfade zu
bauen wuerde nur ins Leere zeigen.

## Erster Schritt

```bash
curl -fsSL -o ~/Desktop/MAC_AGENT_SCAN.command "https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-XKISu/setup-system-architecture/06-mac-agents/MAC_AGENT_SCAN.command" && chmod +x ~/Desktop/MAC_AGENT_SCAN.command && bash ~/Desktop/MAC_AGENT_SCAN.command
```

Scannt (rein lesend): Hardware (Chip/RAM, fuer "was laeuft gut hier"),
Ollama + installierte Modelle, LM Studio, GPT4All, llama.cpp/koboldcpp,
Homebrew-KI-Pakete, und sucht nach OpenClaw in den ueblichen Orten.

Ausgabe zurueck in den Chat -> darauf aufbauend werden die
Start-Icon-Ordner und Memory-Pfad-Shortcuts gebaut.
