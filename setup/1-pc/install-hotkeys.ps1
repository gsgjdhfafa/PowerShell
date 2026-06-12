#Requires -Version 5.1
<#
Installs the ZF global hotkey system:
  1. Ensures AutoHotkey v2 is installed (via winget).
  2. Copies zf-hotkeys.ahk + alle Helper-Skripte (dedup, extract-content,
     hover-explain) nach C:\Users\Admin\Documents\zf-hotkeys\
  3. Drops a Startup-folder shortcut so AHK auto-starts at login.
  4. Launches the script immediately.

Run as the regular user (NOT elevated). Idempotent.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetDir = Join-Path $env:USERPROFILE 'Documents\zf-hotkeys'

# Skripte, die mit-installiert werden (Quelle -> nur Dateiname, Ziel ist $targetDir)
$payload = @(
    'zf-hotkeys.ahk'
    'dedup-and-version.ps1'
    'extract-content.ps1'
    'hover-explain.ps1'
)
foreach ($name in $payload) {
    if (-not (Test-Path -LiteralPath (Join-Path $scriptDir $name))) {
        throw "Quelle fehlt: $name"
    }
}
$ahkDest = Join-Path $targetDir 'zf-hotkeys.ahk'

# 1) AutoHotkey v2 installieren falls noch nicht da
$ahkExe = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe"
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $ahkExe) {
    Write-Host '[install-hotkeys] AutoHotkey v2 nicht gefunden — installiere via winget...'
    & winget install -e --id AutoHotkey.AutoHotkey --silent --accept-source-agreements --accept-package-agreements
    $ahkExe = @(
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $ahkExe) {
        throw 'AutoHotkey v2 konnte nicht installiert werden. Bitte manuell installieren.'
    }
}
Write-Host "[install-hotkeys] AutoHotkey: $ahkExe"

# 2) Skripte in Ziel-Ordner kopieren
if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
foreach ($name in $payload) {
    Copy-Item -LiteralPath (Join-Path $scriptDir $name) -Destination (Join-Path $targetDir $name) -Force
}
Write-Host "[install-hotkeys] Skripte kopiert nach: $targetDir"

# 3) Startup-Shortcut anlegen
$startup  = [Environment]::GetFolderPath('Startup')
$lnkPath  = Join-Path $startup 'zf-hotkeys.lnk'
$wsh      = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($lnkPath)
$shortcut.TargetPath       = $ahkExe
$shortcut.Arguments        = '"' + $ahkDest + '"'
$shortcut.WorkingDirectory = $targetDir
$shortcut.WindowStyle      = 7
$shortcut.Description      = 'ZF Global Hotkeys (Alt+Ctrl chords)'
$shortcut.Save()
Write-Host "[install-hotkeys] Startup-Shortcut: $lnkPath"

# 4) Sofort starten (vorher evtl. laufende Instanz beenden)
Get-Process -Name 'AutoHotkey*' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.MainWindowTitle -like '*zf-hotkeys*' } |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $ahkExe -ArgumentList "`"$ahkDest`"" -WorkingDirectory $targetDir
Write-Host '[install-hotkeys] Script laeuft. Tray-Icon: gruenes H. Right-Click -> Reload Script bei Aenderungen.'
