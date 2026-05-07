#requires -Version 5.1
<#
  One-Shot PC Bootstrap. Verkettet alle PC-Skripte. Idempotent.
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\run-all.ps1
  Mit Optionen:
    powershell -ExecutionPolicy Bypass -File .\run-all.ps1 `
        -Mode Dark -AccentHex '#7B61FF' `
        -Wallpaper 'C:\Users\<du>\Pictures\wall.jpg'
#>
param(
    [ValidateSet('Dark','Light')] [string]$Mode = 'Dark',
    [string]$AccentHex = '#0078D4',
    [string]$Wallpaper
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

Write-Host ""
Write-Host "[done] PC bootstrap fertig."
