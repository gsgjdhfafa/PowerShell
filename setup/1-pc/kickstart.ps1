#requires -Version 5.1
<#
  ZF Kickstart — Von 0 zu lauffaehigem PC in einem Befehl.
  Idempotent. Kein Admin noetig fuer den Hauptteil.
  Aufruf (einfach in PowerShell paste, Enter):
    iwr 'https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-DvgRI/setup/1-pc/kickstart.ps1' -UseBasicParsing | iex

  Wenn Repo privat: erst clonen, dann
    powershell -ExecutionPolicy Bypass -File setup\1-pc\kickstart.ps1

  Was passiert:
    1. winget pruefen, git + gh installieren falls fehlt.
    2. Repo nach %USERPROFILE%\zf clonen (oder pullen).
    3. run-all.ps1 ausfuehren (Brave + Style + Default + Dev-Toolchain).
    4. install-chat-apps.ps1 ausfuehren (Telegram + WhatsApp + Ollama).
    5. Hinweise was als naechstes (Login, WSL, VPS, Notion ...).
#>

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '==============================================='
Write-Host '  ZF KICKSTART — PC-Bootstrap'
Write-Host '==============================================='
Write-Host ''

# --- 1. winget vorhanden? ---------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget fehlt. Windows Update ausfuehren, dann erneut.'
}

# --- 2. git + gh sicherstellen ---------------------------------------------
function EnsureWinget($id) {
    $present = winget list --id $id -e 2>$null
    if ($LASTEXITCODE -eq 0 -and ($present -match [regex]::Escape($id))) {
        Write-Host "[ok]   $id schon da"
        return
    }
    Write-Host "[..]   $id installieren"
    winget install --id $id -e --silent `
        --accept-source-agreements --accept-package-agreements | Out-Null
    Write-Host "[ok]   $id installiert"
}

EnsureWinget 'Git.Git'
EnsureWinget 'GitHub.cli'

# PATH frisch laden, damit git/gh im aktuellen Fenster gehen
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + `
            [Environment]::GetEnvironmentVariable('Path','User')

# --- 3. Repo clonen oder updaten -------------------------------------------
$repoDir = Join-Path $HOME 'zf'
$branch  = 'claude/setup-system-architecture-DvgRI'
$url     = 'https://github.com/gsgjdhfafa/PowerShell.git'

if (-not (Test-Path (Join-Path $repoDir '.git'))) {
    Write-Host "[..]   clone -> $repoDir"
    git clone $url $repoDir
} else {
    Write-Host "[ok]   repo existiert -> pull"
    git -C $repoDir fetch --all --prune
}
git -C $repoDir checkout $branch
git -C $repoDir pull --ff-only origin $branch

# --- 4. PC-Skripte ---------------------------------------------------------
Push-Location $repoDir
try {
    Write-Host ''
    Write-Host '== run-all.ps1 (Brave + Style + Default + Dev-Toolchain) =='
    powershell -ExecutionPolicy Bypass -File 'setup\1-pc\run-all.ps1'

    Write-Host ''
    Write-Host '== install-chat-apps.ps1 (Telegram + WhatsApp + Ollama) =='
    powershell -ExecutionPolicy Bypass -File 'setup\1-pc\install-chat-apps.ps1'
}
finally {
    Pop-Location
}

# --- 5. Naechste Schritte --------------------------------------------------
Write-Host ''
Write-Host '==============================================='
Write-Host '  [done] PC-Kickstart fertig.'
Write-Host '==============================================='
Write-Host ''
Write-Host 'Naechste Schritte (manuell, je 1-3 Min):'
Write-Host ''
Write-Host '  gh auth login                            # GitHub'
Write-Host '  bw login                                 # Bitwarden'
Write-Host '  claude /login                            # Anthropic'
Write-Host '  codex                                    # OpenAI Codex'
Write-Host '  ollama launch openclaw                   # OpenClaw'
Write-Host ''
Write-Host '  Telegram Desktop oeffnen + Nummer + SMS-Code'
Write-Host '  WhatsApp Desktop oeffnen + QR-Code mit Handy scannen'
Write-Host ''
Write-Host 'Optional fuer Hermes Agent / OpenCode (WSL-Setup, ~10 min + Reboot):'
Write-Host '  Rechtsklick Startmenue -> "Terminal (Administrator)"'
Write-Host "  powershell -ExecutionPolicy Bypass -File `"$repoDir\setup\1-pc\install-wsl.ps1`""
Write-Host ''
Write-Host 'VPS (Hetzner Cloud Console, nicht Robot!):'
Write-Host '  https://console.hetzner.cloud -> Project -> Add Server'
Write-Host '  -> Ubuntu 24.04 + CX22 (~4.51 EUR/Monat) + SSH-Key aus dev-setup.ps1'
Write-Host ''
Write-Host 'Walkthrough fuer den Rest:'
Write-Host "  $repoDir\setup\QUICKSTART.md"
