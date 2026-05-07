#requires -Version 5.1
<#
  Windows stylisch + clean. Idempotent. User-Scope (kein Admin noetig).
  Aufruf:  powershell -ExecutionPolicy Bypass -File .\style-windows.ps1
  Optional Wallpaper:  -Wallpaper 'C:\Pfad\zu\bild.jpg'
#>
param(
    [string]$Wallpaper,
    [ValidateSet('Dark','Light')] [string]$Mode = 'Dark',
    # Akzent-Hex (BGR-Reihenfolge im Registry, wir konvertieren)
    [string]$AccentHex = '#0078D4'
)

$ErrorActionPreference = 'Stop'

function Set-Reg {
    param($Path, $Name, $Value, $Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

# --- 1. Dark / Light Mode -----------------------------------------------------
$personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$dark = ($Mode -eq 'Dark')
Set-Reg $personalize 'AppsUseLightTheme'    ([int](-not $dark))
Set-Reg $personalize 'SystemUsesLightTheme' ([int](-not $dark))
Write-Host "[ok] Mode=$Mode"

# --- 2. Akzentfarbe -----------------------------------------------------------
# Hex (#RRGGBB) -> DWORD im Format 0xFFBBGGRR
$h = $AccentHex.TrimStart('#')
$r = [Convert]::ToInt32($h.Substring(0,2),16)
$g = [Convert]::ToInt32($h.Substring(2,2),16)
$b = [Convert]::ToInt32($h.Substring(4,2),16)
$accentDword = [int]((0xFF -shl 24) -bor ($b -shl 16) -bor ($g -shl 8) -bor $r)

$dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
Set-Reg $dwm 'AccentColor'        $accentDword
Set-Reg $dwm 'ColorizationColor'  $accentDword
Set-Reg $dwm 'ColorPrevalence'    1   # Akzent auf Titelleisten + Taskleiste
Set-Reg $dwm 'EnableWindowColorization' 1

$accent = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
Set-Reg $accent 'AccentColorMenu' $accentDword
Set-Reg $accent 'StartColorMenu'  $accentDword
Write-Host "[ok] Accent=$AccentHex"

# --- 3. Transparenz / Effekte -------------------------------------------------
Set-Reg $personalize 'EnableTransparency' 1

# --- 4. Explorer aufgeraeumt --------------------------------------------------
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv 'HideFileExt'              0   # Endungen anzeigen
Set-Reg $adv 'Hidden'                   1   # versteckte anzeigen
Set-Reg $adv 'ShowSuperHidden'          0
Set-Reg $adv 'LaunchTo'                 1   # 1 = This PC, 2 = Quick Access
Set-Reg $adv 'ShowTaskViewButton'       0
Set-Reg $adv 'TaskbarDa'                0   # Widgets aus
Set-Reg $adv 'TaskbarMn'                0   # Chat aus
Set-Reg $adv 'TaskbarAl'                0   # Taskbar links (Win11)
Set-Reg $adv 'SearchboxTaskbarMode'     1   # nur Lupe
Set-Reg $adv 'Start_Layout'             1   # mehr Pins, weniger Empfehlungen (Win11)

# Explorer in Win11: kompakte Ansicht
Set-Reg $adv 'UseCompactMode'           1

# --- 5. Suche/Datenschutz Quick wins -----------------------------------------
$searchSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
Set-Reg $searchSettings 'IsDeviceSearchHistoryEnabled' 0

$content = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
Set-Reg $content 'SubscribedContent-338388Enabled' 0   # Start: Vorschlaege
Set-Reg $content 'SubscribedContent-338389Enabled' 0   # Tipps
Set-Reg $content 'SubscribedContent-310093Enabled' 0   # Lock screen Werbung
Set-Reg $content 'SystemPaneSuggestionsEnabled'    0

# --- 6. Maus, Snap, Schreibtisch ---------------------------------------------
Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' 0 String
$ww = 'HKCU:\Control Panel\Desktop\WindowMetrics'
# (Schriftgroessen lassen wir bewusst auf Default; nichts kaputtmachen)

# Snap-Assist + Layouts
Set-Reg 'HKCU:\Control Panel\Desktop' 'WindowArrangementActive' 1 String
Set-Reg $adv 'EnableSnapAssistFlyout' 1
Set-Reg $adv 'SnapAssist'             1
Set-Reg $adv 'JointResize'            1

# --- 7. Wallpaper -------------------------------------------------------------
if ($Wallpaper) {
    if (-not (Test-Path $Wallpaper)) { throw "Wallpaper nicht gefunden: $Wallpaper" }
    Set-Reg 'HKCU:\Control Panel\Desktop' 'Wallpaper'      $Wallpaper String
    Set-Reg 'HKCU:\Control Panel\Desktop' 'WallpaperStyle' '10'      String  # 10 = Fill
    Set-Reg 'HKCU:\Control Panel\Desktop' 'TileWallpaper'  '0'       String

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Wp {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int u, int i, string p, int f);
}
"@
    [Wp]::SystemParametersInfo(0x14, 0, $Wallpaper, 0x01 -bor 0x02) | Out-Null
    Write-Host "[ok] Wallpaper gesetzt."
}

# --- 8. Explorer neustarten, damit Aenderungen greifen -----------------------
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
Start-Process explorer

Write-Host '[done] Style angewendet. Bei Bedarf einmal abmelden + anmelden.'
