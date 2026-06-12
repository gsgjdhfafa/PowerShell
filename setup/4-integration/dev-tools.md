# Best-Practice "Buero/Hacker" Setups

Kurzliste, was Power-User auf einer frischen Maschine immer haben.
`setup/1-pc/dev-setup.ps1` deckt das Meiste idempotent ab.

## Toolchain (CLI)
- **PowerShell 7**           — modernere Shell, plattformuebergreifend
- **Windows Terminal**       — Tab-Terminal, Default = PowerShell 7
- **Git**                    — config + ssh-key automatisch
- **GitHub CLI (gh)**        — `gh pr create`, `gh repo clone`, `gh auth login`
- **Node.js LTS + npm**      — fuer Tooling und globale CLIs
- **Claude Code (`claude`)** — `npm i -g @anthropic-ai/claude-code`
- **OpenAI Codex CLI (`codex`)** — `npm i -g @openai/codex`
- **Bitwarden CLI (`bw`)**   — Passwords in Skripten/Shell
- **uv**                     — Python + venv all-in-one
- **7zip**                   — Archivieren ohne Browser
- **Oh My Posh**             — schoenes, schnelles Prompt

## GUI
- **VS Code**                — Editor + Remote SSH/WSL
- **PowerToys**              — FancyZones (Tiling), PowerRename, Run, Awake
- **Brave**                  — einziger Browser (siehe `setup-brave.ps1`)
- **Telegram Desktop**       — Input + Files
- **Notion Desktop** (opt.)  — geht auch als Brave-Tab

## Defaults / Hygiene
- SSH-Key ed25519 erzeugt, Pubkey wird im Skript am Ende ausgegeben.
- Git Default-Branch `main`, `pull.rebase=false`, `core.autocrlf=input`.
- Windows Terminal Default = PowerShell 7.
- PowerShell Profil mit Aliases (`g`=git, `..`, `ll`, `gst`, `gco`, `gp`).

## Aufruf
```
powershell -ExecutionPolicy Bypass -File setup/1-pc/dev-setup.ps1 `
    -GitName 'Vorname Nachname' -GitEmail 'du@example.com'
# ohne GUI-Apps:
powershell -ExecutionPolicy Bypass -File setup/1-pc/dev-setup.ps1 -SkipGui
```

## Wo was hingehoert
| Tool         | Login danach                                     |
|--------------|--------------------------------------------------|
| `gh`         | `gh auth login` (GitHub Token)                   |
| `claude`     | `claude` -> `/login`                             |
| `codex`      | `codex` -> Login-Flow                            |
| `bw`         | `bw login`, dann `bw unlock` -> `BW_SESSION` env |
| `git`        | erledigt SSH-Key (oben angezeigt)                |
