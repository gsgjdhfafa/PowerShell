#requires -Version 5.1
<#
  ZF Analyse — Read-only Inventur deines PCs.
  Zeigt was schon da ist und was zf-all.ps1 noch installieren wuerde.
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\analyze.ps1
  Oder per One-Liner aus dem Web:
    irm 'https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-DvgRI/setup/1-pc/analyze.ps1' | iex
#>

$ErrorActionPreference = 'Continue'

function Section($name) {
    Write-Host ''
    Write-Host "== $name =="
}

function Check($label, $hasIt, $version = $null, $note = $null) {
    $mark = if ($hasIt) { '[ok]  ' } else { '[--]  ' }
    $vers = if ($version) { " ($version)" } else { '' }
    $noteText = if ($note) { "  - $note" } else { '' }
    Write-Host "  $mark $label$vers$noteText"
    if (-not $hasIt) { $script:missing += $label }
}

function HasCmd($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function CmdVer($cmd, $arg = '--version') {
    if (-not (HasCmd $cmd)) { return $null }
    try { (& $cmd $arg 2>&1 | Select-Object -First 1) -replace '\s+', ' ' }
    catch { 'installiert' }
}

function HasWinget($id) {
    if (-not (HasCmd winget)) { return $false }
    $out = winget list --id $id -e 2>$null
    ($LASTEXITCODE -eq 0) -and ($out -match [regex]::Escape($id))
}

$script:missing = @()

Write-Host ''
Write-Host '==============================================='
Write-Host '  ZF ANALYSE — was hat dein PC schon?'
Write-Host '==============================================='

# --- System ----------------------------------------------------------------
Section 'System'
$os = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Host "  os    : $os"
Write-Host "  user  : $env:USERNAME"
Write-Host "  home  : $HOME"
Write-Host "  arch  : $env:PROCESSOR_ARCHITECTURE"
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
Write-Host "  ram   : $ram GB"
$pwsh = $PSVersionTable.PSVersion.ToString()
Write-Host "  pwsh  : $pwsh"

# --- CLI Tools -------------------------------------------------------------
Section 'CLI-Tools (PATH)'
Check 'winget'   (HasCmd winget)   (CmdVer winget '--version')
Check 'git'      (HasCmd git)      (CmdVer git    '--version')
Check 'gh'       (HasCmd gh)       (CmdVer gh     '--version')
Check 'node'    ((HasCmd node) -and (node -v 2>$null) -match '^v(20|22)') (CmdVer node '-v')
Check 'npm'      (HasCmd npm)      (CmdVer npm    '--version')
Check 'claude'   (HasCmd claude)   (CmdVer claude '--version')
Check 'codex'    (HasCmd codex)    (CmdVer codex  '--version')
Check 'bw'       (HasCmd bw)       (CmdVer bw     '--version')
Check 'uv'       (HasCmd uv)       (CmdVer uv     '--version')
Check 'ollama'   (HasCmd ollama)   (CmdVer ollama '--version')
Check 'docker'   (HasCmd docker)   (CmdVer docker '--version')

# --- Browser + Apps --------------------------------------------------------
Section 'GUI-Apps (winget)'
Check 'Brave'                  (HasWinget 'Brave.Brave')
Check 'Bitwarden Desktop'      (HasWinget 'Bitwarden.Bitwarden')
Check 'Windows Terminal'       (HasWinget 'Microsoft.WindowsTerminal')
Check 'VS Code'                (HasWinget 'Microsoft.VisualStudioCode')
Check 'PowerToys'              (HasWinget 'Microsoft.PowerToys')
Check 'Telegram Desktop'       (HasWinget 'Telegram.TelegramDesktop')
$waInstalled = (HasWinget 'WhatsApp.WhatsApp') -or `
    (Get-AppxPackage -Name '5319275A.WhatsAppDesktop' -ErrorAction SilentlyContinue)
Check 'WhatsApp Desktop'       ([bool]$waInstalled)
Check 'PowerShell 7'           (HasWinget 'Microsoft.PowerShell')
Check 'Oh My Posh'             (HasWinget 'JanDeDobbeleer.OhMyPosh')
Check '7zip'                   (HasWinget '7zip.7zip')

# --- WSL -------------------------------------------------------------------
Section 'WSL'
$wslOk = $false
try {
    wsl --status *>$null
    if ($LASTEXITCODE -eq 0) { $wslOk = $true }
} catch {}
Check 'WSL aktiv' $wslOk

if ($wslOk) {
    Write-Host '  Distros:'
    $distros = wsl --list --verbose 2>$null
    if ($distros) {
        $distros | ForEach-Object { Write-Host "    $_" }
    } else {
        Write-Host '    (keine)'
    }
}

# --- Ollama-Modelle --------------------------------------------------------
Section 'Ollama-Modelle (lokal Windows)'
if (HasCmd ollama) {
    try {
        $models = ollama list 2>$null
        if ($models) {
            $models | Select-Object -Skip 1 | ForEach-Object {
                $line = $_.Trim()
                if ($line) { Write-Host "  $line" }
            }
        }
    } catch { Write-Host '  (ollama-Daemon laeuft nicht — `ollama serve` starten)' }
} else {
    Write-Host '  (Ollama nicht installiert)'
}

# --- Repo + SSH ------------------------------------------------------------
Section 'Repo + Keys'
$repoDir = Join-Path $HOME 'zf'
$repoExists = Test-Path (Join-Path $repoDir '.git')
Check "Repo $repoDir" $repoExists
if ($repoExists) {
    Push-Location $repoDir
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $head   = git rev-parse --short HEAD 2>$null
    Pop-Location
    Write-Host "    branch=$branch head=$head"
}

$sshKey = Join-Path $HOME '.ssh\id_ed25519.pub'
$hasKey = Test-Path $sshKey
Check 'SSH-Pubkey ed25519' $hasKey
if ($hasKey) { Write-Host "    -> $sshKey" }

# --- Git-Config ------------------------------------------------------------
Section 'Git-Config'
if (HasCmd git) {
    $name  = git config --global user.name  2>$null
    $email = git config --global user.email 2>$null
    if ($name -and $email) {
        Write-Host "  [ok]  user.name=$name  user.email=$email"
    } else {
        Write-Host '  [--]  user.name/email nicht gesetzt'
        $script:missing += 'git-config'
    }
}

# --- Login-Status (heuristisch) --------------------------------------------
Section 'Login-Status'
function CheckLogin($name, $cmd, $cmdArgs) {
    if (-not (HasCmd $cmd)) { return }
    try {
        $out = & $cmd @cmdArgs 2>&1
        $ok = $LASTEXITCODE -eq 0
        $marker = if ($ok) { '[ok]  ' } else { '[--]  ' }
        Write-Host "  $marker $name"
    } catch { Write-Host "  [--]  $name" }
}
CheckLogin 'gh   (GitHub CLI)'       'gh'    @('auth','status')
CheckLogin 'bw   (Bitwarden CLI)'    'bw'    @('status')

# --- Zusammenfassung --------------------------------------------------------
Section 'Zusammenfassung'
if ($script:missing.Count -eq 0) {
    Write-Host '  Alles installiert. Nur noch interaktive Logins offen.'
} else {
    Write-Host "  $($script:missing.Count) Eintraege offen:"
    $script:missing | Sort-Object -Unique | ForEach-Object { Write-Host "    - $_" }
    Write-Host ''
    Write-Host '  -> diese werden vom Master-Skript installiert:'
    Write-Host '       powershell -ExecutionPolicy Bypass -File "$HOME\zf\setup\1-pc\zf-all.ps1"'
}

Write-Host ''
Write-Host '  Manuell zu erledigen (Login-Flows):'
Write-Host '    gh auth login            # GitHub'
Write-Host '    bw login                 # Bitwarden'
Write-Host '    claude /login            # Anthropic'
Write-Host '    codex                    # OpenAI Codex'
Write-Host '    Telegram Desktop oeffnen + Nummer + SMS'
Write-Host '    WhatsApp Desktop oeffnen + QR mit Handy'
Write-Host ''
Write-Host '  WSL/Hermes (falls noch nicht):'
Write-Host '    in WSL: bash /mnt/c/Users/$env:USERNAME/zf/setup/1-pc/install-agents-in-wsl.sh'
Write-Host '    in WSL: ollama launch hermes'
Write-Host ''
