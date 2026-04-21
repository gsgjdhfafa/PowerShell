#requires -Version 5.1
<#
  PC Setup - Brave als einziges Interface.
  Idempotent. Als normaler User ausfuehren (kein Admin noetig).
  Aufruf:  powershell -ExecutionPolicy Bypass -File .\setup-brave.ps1
#>

$ErrorActionPreference = 'Stop'

# --- 1. Brave via winget sicherstellen ----------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget fehlt. Windows Update ausfuehren, dann erneut starten.'
}

$brave = winget list --id Brave.Brave -e 2>$null
if ($LASTEXITCODE -ne 0 -or -not ($brave -match 'Brave')) {
    winget install --id Brave.Brave -e --accept-source-agreements --accept-package-agreements
} else {
    Write-Host '[ok] Brave bereits installiert.'
}

# --- 2. Bitwarden -------------------------------------------------------------
$bw = winget list --id Bitwarden.Bitwarden -e 2>$null
if ($LASTEXITCODE -ne 0 -or -not ($bw -match 'Bitwarden')) {
    winget install --id Bitwarden.Bitwarden -e --accept-source-agreements --accept-package-agreements
} else {
    Write-Host '[ok] Bitwarden bereits installiert.'
}

# --- 3. Start-Tabs ueber Brave Policy (Managed Preferences) ------------------
# HKCU Policy => keine Admin-Rechte noetig, greift bei naechstem Brave-Start.
$pol = 'HKCU:\Software\Policies\BraveSoftware\Brave'
if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }

$startUrls = @(
    'https://www.notion.so',
    'https://mail.google.com',
    'https://calendar.google.com',
    'https://tasks.google.com'
)

New-ItemProperty -Path $pol -Name 'RestoreOnStartup'      -PropertyType DWord  -Value 4 -Force | Out-Null
# RestoreOnStartupURLs ist MultiString
New-ItemProperty -Path $pol -Name 'RestoreOnStartupURLs'  -PropertyType MultiString -Value $startUrls -Force | Out-Null
New-ItemProperty -Path $pol -Name 'HomepageIsNewTabPage'  -PropertyType DWord  -Value 0 -Force | Out-Null
New-ItemProperty -Path $pol -Name 'HomepageLocation'      -PropertyType String -Value 'https://www.notion.so' -Force | Out-Null
New-ItemProperty -Path $pol -Name 'ShowHomeButton'        -PropertyType DWord  -Value 1 -Force | Out-Null

Write-Host '[ok] Start-Tabs registriert.'

# --- 4. Bookmarks -------------------------------------------------------------
# Brave liest Bookmarks aus dem User-Profil. Wir schreiben eine Bookmarks-Datei,
# wenn Brave laeuft, wuerde sie ueberschrieben => Brave schliessen.
Get-Process brave -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$profileDir = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data\Default'
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

function New-Bm($name, $url, $id) {
    [pscustomobject]@{
        date_added = '0'; guid = [guid]::NewGuid().ToString(); id = "$id"
        name = $name; type = 'url'; url = $url
    }
}
function New-Folder($name, $id, $children) {
    [pscustomobject]@{
        children = $children; date_added = '0'; date_modified = '0'
        guid = [guid]::NewGuid().ToString(); id = "$id"; name = $name; type = 'folder'
    }
}

$bar = New-Folder 'bookmark_bar' 1 @(
    (New-Folder 'Dashboard' 10 @(
        (New-Bm 'Notion'   'https://www.notion.so'        11),
        (New-Bm 'Gmail'    'https://mail.google.com'      12),
        (New-Bm 'Calendar' 'https://calendar.google.com'  13),
        (New-Bm 'Tasks'    'https://tasks.google.com'     14)
    )),
    (New-Folder 'Communication' 20 @(
        (New-Bm 'Telegram Web' 'https://web.telegram.org' 21),
        (New-Bm 'Gmail'        'https://mail.google.com'  22)
    )),
    (New-Folder 'Operations' 30 @(
        (New-Bm 'Drive' 'https://drive.google.com' 31),
        (New-Bm 'Docs'  'https://docs.google.com'  32),
        (New-Bm 'Keep'  'https://keep.google.com'  33)
    )),
    (New-Folder 'Finance' 40 @(
        (New-Bm 'Bitwarden' 'https://vault.bitwarden.com' 41)
    )),
    (New-Folder 'AI' 50 @(
        (New-Bm 'ChatGPT' 'https://chat.openai.com' 51),
        (New-Bm 'Claude'  'https://claude.ai'       52)
    ))
)

$other    = New-Folder 'other'    2 @()
$synced   = New-Folder 'synced'   3 @()

$book = [pscustomobject]@{
    checksum = ''
    roots = [pscustomobject]@{
        bookmark_bar  = $bar
        other         = $other
        synced        = $synced
    }
    version = 1
}

$json = $book | ConvertTo-Json -Depth 10
$target = Join-Path $profileDir 'Bookmarks'
if (Test-Path $target) { Copy-Item $target "$target.bak" -Force }
$json | Set-Content -Path $target -Encoding UTF8

Write-Host "[ok] Bookmarks geschrieben: $target"
Write-Host '[done] PC fertig. Brave starten.'
