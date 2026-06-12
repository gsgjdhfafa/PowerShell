#requires -Version 5.1
<#
  One-Shot PC Bootstrap. Verkettet alle PC-Skripte. Idempotent.
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\run-all.ps1
  Mit Optionen:
    powershell -ExecutionPolicy Bypass -File .\run-all.ps1 `
        -Mode Dark -AccentHex '#7B61FF' `
        -Wallpaper 'C:\Users\<du>\Pictures\wall.jpg' `
        -GitName 'Vorname Nachname' -GitEmail 'du@example.com'
#>
param(
    [ValidateSet('Dark','Light')] [string]$Mode = 'Dark',
    [string]$AccentHex = '#0078D4',
    [string]$Wallpaper,
    [string]$GitName,
    [string]$GitEmail,
    [switch]$SkipDev,
    [switch]$SkipGui
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($name, $script, $args = @{}) {
    Write-Host ""
    Write-Host "==> $name"
    & $script @args
}

# 1) Brave + Bitwarden + Bookmarks + Start-Tabs
Step 'Brave Setup' (Join-Path $here 'setup-brave.ps1')

# 2) Windows Style
$styleArgs = @{ Mode = $Mode; AccentHex = $AccentHex }
if ($Wallpaper) { $styleArgs['Wallpaper'] = $Wallpaper }
Step 'Windows Style' (Join-Path $here 'style-windows.ps1') $styleArgs

# 3) Default Browser + Tab-Verhalten
Step 'Links/Default Browser' (Join-Path $here 'links-newtab.ps1')

# 4) Dev-Toolchain (Claude Code, Codex, gh, etc.)
if (-not $SkipDev) {
    $devArgs = @{}
    if ($GitName)  { $devArgs['GitName']  = $GitName }
    if ($GitEmail) { $devArgs['GitEmail'] = $GitEmail }
    if ($SkipGui)  { $devArgs['SkipGui']  = $true }
    Step 'Dev Toolchain' (Join-Path $here 'dev-setup.ps1') $devArgs
}

Write-Host ""
Write-Host "[done] PC bootstrap fertig."
