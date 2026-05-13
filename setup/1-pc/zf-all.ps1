#requires -Version 5.1
<#
  ZF ALL — Ein-Aufruf-Komplett-Bootstrap fuer Windows-PC.
  Idempotent. Eskaliert sich automatisch auf Admin (UAC).

  Aufruf (in normaler PowerShell, kein Admin-Fenster noetig):
    irm 'https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-DvgRI/setup/1-pc/zf-all.ps1' | iex

  Oder lokal:
    powershell -ExecutionPolicy Bypass -File .\zf-all.ps1

  Was alles passiert:
    1. UAC-Dialog -> Admin-Rechte
    2. winget Basics: Git, gh CLI
    3. Repo nach %USERPROFILE%\zf clonen/pullen
    4. run-all.ps1: Brave + Bitwarden + Bookmarks + Style + Default-Browser + Dev-Toolchain
    5. install-chat-apps.ps1: Telegram + WhatsApp + Ollama
    6. WSL2 + Ubuntu installieren (no-launch)
    7. Reboot-Prompt
    8. Nach Reboot manuell:
         a) Start-Menue -> Ubuntu starten -> User + Passwort vergeben
         b) Im Ubuntu:  bash /mnt/c/Users/<DU>/zf/setup/1-pc/install-agents-in-wsl.sh
         c) Im Ubuntu:  ollama launch hermes
#>

$ErrorActionPreference = 'Stop'

# --- 0. Self-Elevate -------------------------------------------------------
$me = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[..]   Skript braucht Admin-Rechte. UAC-Dialog kommt jetzt.'
    $scriptPath = if ($MyInvocation.MyCommand.Path) {
        $MyInvocation.MyCommand.Path
    } else {
        # Wenn ueber iex/iwr aufgerufen, schreiben wir uns selbst lokal raus.
        $tmp = Join-Path $env:TEMP 'zf-all.ps1'
        $MyInvocation.MyCommand.Definition | Set-Content -Path $tmp -Encoding UTF8
        $tmp
    }
    Start-Process powershell -Verb RunAs `
        -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

Write-Host ''
Write-Host '==============================================='
Write-Host '  ZF ALL — PC + WSL + Agents Bootstrap'
Write-Host '==============================================='
Write-Host ''

# --- 1. winget Basics ------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget fehlt. Windows Update ausfuehren, dann erneut.'
}

function EnsureWinget($id) {
    $present = winget list --id $id -e 2>$null
    if ($LASTEXITCODE -eq 0 -and ($present -match [regex]::Escape($id))) {
        Write-Host "[ok]   $id"
        return
    }
    Write-Host "[..]   $id installieren"
    winget install --id $id -e --silent `
        --accept-source-agreements --accept-package-agreements | Out-Null
}

EnsureWinget 'Git.Git'
EnsureWinget 'GitHub.cli'

$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + `
            [Environment]::GetEnvironmentVariable('Path','User')

# --- 2. Repo clonen / updaten ----------------------------------------------
$repoDir = Join-Path $HOME 'zf'
$branch  = 'claude/setup-system-architecture-DvgRI'
$url     = 'https://github.com/gsgjdhfafa/PowerShell.git'

if (-not (Test-Path (Join-Path $repoDir '.git'))) {
    Write-Host "[..]   clone -> $repoDir"
    git clone $url $repoDir
} else {
    Write-Host "[ok]   repo schon da -> fetch + checkout"
    git -C $repoDir fetch --all --prune
}
git -C $repoDir checkout $branch
git -C $repoDir pull --ff-only origin $branch

# --- 3. PC-Skripte ---------------------------------------------------------
Push-Location $repoDir
try {
    Write-Host ''
    Write-Host '== run-all.ps1 =='
    powershell -ExecutionPolicy Bypass -File 'setup\1-pc\run-all.ps1'

    Write-Host ''
    Write-Host '== install-chat-apps.ps1 =='
    powershell -ExecutionPolicy Bypass -File 'setup\1-pc\install-chat-apps.ps1'
}
finally {
    Pop-Location
}

# --- 4. WSL2 + Ubuntu installieren -----------------------------------------
Write-Host ''
Write-Host '== WSL2 + Ubuntu =='

$wslAvailable = $false
try {
    wsl --status *>$null
    if ($LASTEXITCODE -eq 0) { $wslAvailable = $true }
} catch {}

if (-not $wslAvailable) {
    Write-Host '[..]   wsl --install (zieht Kernel + Ubuntu)'
    wsl --install --no-launch
    $needsReboot = $true
} else {
    Write-Host '[ok]   WSL ist installiert'
    wsl --set-default-version 2 | Out-Null
    wsl --update | Out-Null
    $distros = wsl --list --quiet 2>$null
    if ($distros -notmatch 'Ubuntu') {
        Write-Host '[..]   Ubuntu Distro nachinstallieren'
        wsl --install -d Ubuntu --no-launch
        $needsReboot = $true
    } else {
        Write-Host '[ok]   Ubuntu vorhanden'
        $needsReboot = $false
    }
}

# --- 5. Naechste Schritte ausgeben + ggf. Reboot ---------------------------
$nextCmd = "bash /mnt/c/Users/$env:USERNAME/zf/setup/1-pc/install-agents-in-wsl.sh"

Write-Host ''
Write-Host '==============================================='
Write-Host '  [done] Windows-Bootstrap fertig.'
Write-Host '==============================================='
Write-Host ''
Write-Host 'NACH DEM REBOOT:'
Write-Host ''
Write-Host '  1. Start-Menue -> "Ubuntu" anklicken'
Write-Host '     -> Username + Passwort vergeben (das ist die Linux-User-ID)'
Write-Host ''
Write-Host '  2. Im Ubuntu-Fenster eintippen (Copy-Paste):'
Write-Host "       $nextCmd"
Write-Host ''
Write-Host '  3. Danach im Ubuntu fuer Hermes:'
Write-Host '       ollama launch hermes'
Write-Host ''
Write-Host 'Manuell zu erledigen (PowerShell auf Windows, kein Admin noetig):'
Write-Host '  gh auth login            # GitHub'
Write-Host '  bw login                 # Bitwarden'
Write-Host '  claude /login            # Anthropic'
Write-Host '  codex                    # OpenAI Codex'
Write-Host '  ollama launch openclaw   # OpenClaw'
Write-Host ''
Write-Host '  Telegram Desktop oeffnen -> Nummer eintippen -> SMS-Code'
Write-Host '  WhatsApp Desktop oeffnen -> Handy: Einstellungen -> Verknuepfte Geraete -> QR'
Write-Host ''
Write-Host 'VPS (parallel moeglich, nicht von Reboot blockiert):'
Write-Host '  https://console.hetzner.cloud  ->  New Project -> Add Server'
Write-Host '  Ubuntu 24.04, CX22 (4.51 EUR) oder CX32 (6.80 EUR mit Reserve fuer Ollama)'
Write-Host '  SSH-Key paste (aus dev-setup.ps1-Output / ~/.ssh/id_ed25519.pub)'
Write-Host ''
Write-Host "Walkthrough fuer den Rest:  $repoDir\setup\QUICKSTART.md"
Write-Host ''

if ($needsReboot) {
    Write-Host '[!] REBOOT erforderlich, bevor WSL/Ubuntu nutzbar ist.'
    Write-Host ''
    $r = Read-Host 'Jetzt neu starten? (j/N)'
    if ($r -match '^[jJyY]') {
        Restart-Computer -Force
    } else {
        Write-Host '   OK, bitte spaeter manuell neu starten.'
    }
} else {
    Write-Host '[ok] Kein Reboot noetig. Ubuntu jetzt aus dem Startmenue starten + die Schritte oben.'
}
