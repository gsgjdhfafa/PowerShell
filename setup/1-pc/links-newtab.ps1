#requires -Version 5.1
<#
  Links via Rechtsklick / extern immer in Brave als neuer Tab.
  Idempotent. User-Scope (kein Admin).
  Aufruf:  powershell -ExecutionPolicy Bypass -File .\links-newtab.ps1
#>

$ErrorActionPreference = 'Stop'

function Set-Reg {
    param($Path, $Name, $Value, $Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

# --- 1. Brave Policies: Tab-Verhalten + Kontextmenue --------------------------
$pol = 'HKCU:\Software\Policies\BraveSoftware\Brave'
if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }

# Sitzung wiederherstellen, also bestehende Tabs behalten + neue anhaengen.
Set-Reg $pol 'RestoreOnStartup' 1                  # 1 = letzte Tabs
# Hintergrundmodus aus (sonst werden Brave-Tabs unsichtbar geoeffnet).
Set-Reg $pol 'BackgroundModeEnabled' 0
# Kontextmenue-Eintrag "In Brave oeffnen" aus anderen Browsern erlauben.
Set-Reg $pol 'BrowserAddPersonEnabled' 1
# Sicherstellen, dass das Standard-Kontextmenue NICHT von Policies geblockt ist.
# (Falls jemand "ContextMenuEnabled" auf 0 hatte – wieder an.)
Set-Reg $pol 'ContextMenuEnabled' 1

Write-Host '[ok] Brave Policies geschrieben.'

# --- 2. Brave als Default-Browser registrieren --------------------------------
# Windows 10/11 verlangt fuer den finalen Klick die Settings-UI. Wir oeffnen
# die richtige Stelle und registrieren Brave als waehlbare Option (idempotent).
$brave = @(
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
    "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
    "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $brave) {
    Write-Warning 'Brave nicht gefunden. Erst setup-brave.ps1 ausfuehren.'
} else {
    # Brave selbst hat einen Default-Registrar:
    & $brave --make-default-browser | Out-Null
    Write-Host '[ok] Brave als Default angefragt.'

    # UserChoice in Win11 ist hash-geschuetzt -> wir koennen NICHT direkt setzen.
    # Wir oeffnen die richtige Settings-Seite, ein Klick reicht.
    Start-Process 'ms-settings:defaultapps'
    Write-Host '[!] Settings geoeffnet: bei "Webbrowser" / .htm / .html / http / https Brave waehlen.'
}

# --- 3. Hinweis-Shortcuts (kein Setting, nur Doku) ----------------------------
@'
Maus / Tasten:
  Mittlere Maustaste auf Link        -> neuer Tab im Hintergrund
  Strg + Klick                        -> neuer Tab im Hintergrund
  Strg + Shift + Klick                -> neuer Tab im Vordergrund
  Shift + Klick                       -> neues Fenster
  Strg + Klick auf Tab-Schliessen-X   -> alle anderen Tabs schliessen
Rechtsklick auf Link in Brave:
  "In neuem Tab oeffnen"   |   "In neuem Fenster oeffnen"   |   "In InPrivate-Fenster"
'@ | Write-Host
