#requires -Version 5.1
<#
  WSL2 + Ubuntu installieren fuer Hermes / OpenCode / Linux-Tools.
  ADMIN-PowerShell noetig.
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\install-wsl.ps1

  Was passiert:
    1. WSL + VirtualMachinePlatform aktivieren (Windows-Features).
    2. WSL Update + Default-Version 2 setzen.
    3. Ubuntu als Default-Distro installieren.
    4. Hinweis: Reboot noetig.
    5. Nach Reboot: in Ubuntu-Shell `bash install-agents-in-wsl.sh` ausfuehren.
#>

$ErrorActionPreference = 'Stop'

# --- 1. Admin-Check ----------------------------------------------------------
$me = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Bitte als ADMINISTRATOR ausfuehren (Rechtsklick auf Start -> "Terminal (Administrator)").'
}

# --- 2. WSL-Status pruefen ---------------------------------------------------
$wslExists = $false
try {
    wsl --status *>$null
    if ($LASTEXITCODE -eq 0) { $wslExists = $true }
} catch {}

if (-not $wslExists) {
    Write-Host '[..] wsl --install (Ubuntu wird als Default mitgeladen)'
    wsl --install --no-launch
    Write-Host ''
    Write-Host '[!] REBOOT noetig. Nach dem Neustart:'
    Write-Host '    1. Ubuntu startet automatisch und fragt nach User + Passwort.'
    Write-Host '    2. Danach in der Ubuntu-Shell folgendes laufen lassen:'
    Write-Host ''
    Write-Host '       bash <(curl -fsSL https://raw.githubusercontent.com/gsgjdhfafa/PowerShell/claude/setup-system-architecture-DvgRI/setup/1-pc/install-agents-in-wsl.sh)'
    Write-Host ''
    Write-Host '    (Oder aus dem Repo-Clone: bash setup/1-pc/install-agents-in-wsl.sh)'
    Write-Host ''
    Read-Host 'Druecke Enter um JETZT neu zu starten (oder Strg+C zum Verschieben)'
    Restart-Computer -Force
    exit
}

Write-Host '[ok] WSL ist installiert.'

# --- 3. Default-Version 2 sicherstellen --------------------------------------
wsl --set-default-version 2 | Out-Null
Write-Host '[ok] WSL Default-Version = 2'

# --- 4. WSL Update -----------------------------------------------------------
wsl --update
Write-Host '[ok] WSL updated'

# --- 5. Ubuntu als Distro vorhanden? -----------------------------------------
$distros = wsl --list --quiet 2>$null
if ($distros -notmatch 'Ubuntu') {
    Write-Host '[..] Ubuntu installieren'
    wsl --install -d Ubuntu --no-launch
} else {
    Write-Host '[ok] Ubuntu schon installiert'
}

Write-Host ''
Write-Host '[done] WSL+Ubuntu fertig. Jetzt in Ubuntu-Shell weitermachen:'
Write-Host '   1. Start-Menue -> Ubuntu (oder im Windows Terminal Tab "Ubuntu")'
Write-Host '   2. Im Ubuntu: bash setup/1-pc/install-agents-in-wsl.sh'
