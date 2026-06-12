#requires -Version 5.1
<#
  Power-User PC Setup. Idempotent. User-Scope (winget) wo moeglich.
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\dev-setup.ps1
  Optional:
    -GitName "Vorname Nachname" -GitEmail "you@example.com"
    -SkipGui      keine GUI-Apps (VS Code, PowerToys, Terminal)
#>
param(
    [string]$GitName,
    [string]$GitEmail,
    [switch]$SkipGui
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget fehlt. Windows Update ausfuehren, dann erneut.'
}

function Wg($id) {
    $present = winget list --id $id -e 2>$null
    if ($LASTEXITCODE -eq 0 -and ($present -match [regex]::Escape($id))) {
        Write-Host "[ok]   $id schon da"
        return
    }
    Write-Host "[..]   $id installieren"
    winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
    Write-Host "[ok]   $id installiert"
}

# --- 1. CLI Basics ------------------------------------------------------------
Wg 'Microsoft.PowerShell'              # PowerShell 7
Wg 'Git.Git'
Wg 'GitHub.cli'
Wg 'OpenJS.NodeJS.LTS'                 # Node 20 LTS (npm)
Wg 'Bitwarden.CLI'
Wg 'astral-sh.uv'                      # Python+venv all-in-one (optional, schadet nicht)
Wg 'JanDeDobbeleer.OhMyPosh'           # nice prompt
Wg '7zip.7zip'

# --- 2. GUI (optional) --------------------------------------------------------
if (-not $SkipGui) {
    Wg 'Microsoft.WindowsTerminal'
    Wg 'Microsoft.VisualStudioCode'
    Wg 'Microsoft.PowerToys'           # FancyZones, PowerRename, etc.
    Wg 'Notion.Notion'                 # Desktop-App optional, Brave-Tab geht auch
    Wg 'Telegram.TelegramDesktop'
}

# --- 3. PATH + Refresh --------------------------------------------------------
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + `
            [Environment]::GetEnvironmentVariable('Path','User')

function Have($exe) { Get-Command $exe -ErrorAction SilentlyContinue }

# --- 4. Claude Code + Codex CLI via npm --------------------------------------
if (Have node) {
    if (-not (Have claude)) {
        Write-Host '[..]   @anthropic-ai/claude-code via npm'
        npm install -g '@anthropic-ai/claude-code' | Out-Null
    }
    if (-not (Have codex)) {
        Write-Host '[..]   @openai/codex via npm'
        npm install -g '@openai/codex' | Out-Null
    }
    npm list -g --depth=0 2>$null | Select-String 'claude-code|codex' | ForEach-Object { Write-Host "[ok]   $_" }
} else {
    Write-Warning 'node nicht im PATH. Shell neu oeffnen und dieses Skript erneut starten.'
}

# --- 5. Git Config + SSH Key --------------------------------------------------
if (Have git) {
    if ($GitName)  { git config --global user.name  "$GitName" }
    if ($GitEmail) { git config --global user.email "$GitEmail" }
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global color.ui auto
    Write-Host "[ok]   git: $(git config --global user.name) <$(git config --global user.email)>"

    $sshDir = Join-Path $HOME '.ssh'
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    $key = Join-Path $sshDir 'id_ed25519'
    if (-not (Test-Path $key)) {
        $email = (git config --global user.email)
        if (-not $email) { $email = "$env:USERNAME@$env:COMPUTERNAME" }
        ssh-keygen -t ed25519 -N '' -C "$email" -f $key | Out-Null
        Write-Host "[ok]   SSH-Key: $key"
    } else {
        Write-Host "[ok]   SSH-Key existiert"
    }
    Write-Host '------------ Public Key ------------'
    Get-Content "$key.pub"
    Write-Host '------------------------------------'
    Write-Host '-> in GitHub (Settings/SSH and GPG keys) und beim VPS hinterlegen.'
}

# --- 6. Windows Terminal: Standard auf PowerShell 7 + dunkles Theme ----------
if (-not $SkipGui) {
    $wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wtSettings) {
        try {
            $j = Get-Content $wtSettings -Raw | ConvertFrom-Json
            $pwsh = $j.profiles.list | Where-Object { $_.name -match 'PowerShell$' } | Select-Object -First 1
            if ($pwsh) {
                $j.defaultProfile = $pwsh.guid
                $j | ConvertTo-Json -Depth 50 | Set-Content $wtSettings -Encoding UTF8
                Write-Host '[ok]   Windows Terminal Default = PowerShell 7'
            }
        } catch { Write-Warning "Terminal-Settings konnten nicht angepasst werden: $_" }
    }
}

# --- 7. PowerShell Profil: Oh My Posh + Aliase -------------------------------
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}
$marker = '# ZF-PROFILE-V1'
if (-not (Select-String -Path $profilePath -Pattern $marker -Quiet -ErrorAction SilentlyContinue)) {
    @"
$marker
# Oh My Posh Prompt (wenn installiert)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH/powerlevel10k_rainbow.omp.json" | Invoke-Expression
}
# Quality of life
Set-Alias g  git
Set-Alias k  kubectl 2>`$null
function .. { Set-Location .. }
function ll { Get-ChildItem -Force @args }
function gst { git status @args }
function gco { git checkout @args }
function gp  { git pull --rebase=false @args }
"@ | Add-Content -Path $profilePath -Encoding UTF8
    Write-Host "[ok]   PowerShell-Profil ergaenzt: $profilePath"
} else {
    Write-Host '[ok]   PowerShell-Profil schon eingerichtet'
}

Write-Host ''
Write-Host '[done] dev-setup fertig.'
Write-Host '       -> claude       (CLI starten, danach `claude /login`)'
Write-Host '       -> codex        (CLI starten)'
Write-Host '       -> gh auth login (GitHub CLI)'
Write-Host '       -> bw login     (Bitwarden CLI)'
