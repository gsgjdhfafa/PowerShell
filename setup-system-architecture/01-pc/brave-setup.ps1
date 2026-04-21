# ============================================================
# PC SETUP - Brave als einziges Interface
# Ausfuehren: PowerShell als Administrator
# Idempotent: mehrfach ausfuehrbar
# ============================================================

$ErrorActionPreference = 'Stop'

# --- 1. Winget sicherstellen -----------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget fehlt. Microsoft Store -> 'App Installer' installieren."
}

# --- 2. Kern-Apps installieren (nur was wirklich noetig ist) ---
$apps = @(
    'Brave.Brave',
    'Bitwarden.Bitwarden',
    'Telegram.TelegramDesktop'
)

foreach ($a in $apps) {
    $installed = winget list --id $a -e 2>$null | Select-String $a
    if (-not $installed) {
        winget install --id $a -e --silent --accept-package-agreements --accept-source-agreements
    }
}

# --- 3. Brave Startseiten (Tabs beim Start) --------------------
$braveDir  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default"
$prefsPath = Join-Path $braveDir 'Preferences'

if (-not (Test-Path $braveDir)) {
    New-Item -ItemType Directory -Path $braveDir -Force | Out-Null
}

$startPages = @(
    'https://www.notion.so',
    'https://mail.google.com',
    'https://calendar.google.com',
    'https://tasks.google.com'
)

$prefs = if (Test-Path $prefsPath) {
    Get-Content $prefsPath -Raw | ConvertFrom-Json -Depth 50
} else {
    [ordered]@{} | ConvertTo-Json | ConvertFrom-Json
}

if (-not $prefs.session)       { $prefs | Add-Member session       @{} -Force }
if (-not $prefs.session.startup_urls) { $prefs.session | Add-Member startup_urls @() -Force }

$prefs.session.restore_on_startup = 4   # 4 = liste definierter URLs
$prefs.session.startup_urls       = $startPages

$prefs | ConvertTo-Json -Depth 50 | Set-Content $prefsPath -Encoding UTF8

# --- 4. Bookmark-Struktur --------------------------------------
$bookmarksPath = Join-Path $braveDir 'Bookmarks'
$now = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMicroseconds() + 11644473600000000)

function New-Folder($name, $children) {
    [ordered]@{
        date_added    = $now
        date_modified = $now
        name          = $name
        type          = 'folder'
        children      = $children
    }
}
function New-Url($name, $url) {
    [ordered]@{
        date_added = $now
        name       = $name
        type       = 'url'
        url        = $url
    }
}

$bookmarks = [ordered]@{
    checksum = ''
    roots    = [ordered]@{
        bookmark_bar = New-Folder 'Bookmarks bar' @(
            New-Folder 'Dashboard'      @(
                New-Url 'Notion'   'https://www.notion.so'
                New-Url 'Gmail'    'https://mail.google.com'
                New-Url 'Calendar' 'https://calendar.google.com'
                New-Url 'Tasks'    'https://tasks.google.com'
            )
            New-Folder 'Communication'  @(
                New-Url 'Gmail'    'https://mail.google.com'
                New-Url 'Telegram' 'https://web.telegram.org'
            )
            New-Folder 'Operations'     @(
                New-Url 'Drive' 'https://drive.google.com'
                New-Url 'Docs'  'https://docs.google.com'
            )
            New-Folder 'Finance'        @(
                New-Url 'Bitwarden' 'https://vault.bitwarden.com'
            )
            New-Folder 'AI'             @(
                New-Url 'ChatGPT' 'https://chat.openai.com'
                New-Url 'Claude'  'https://claude.ai'
            )
        )
        other        = New-Folder 'Other bookmarks'     @()
        synced       = New-Folder 'Mobile bookmarks'    @()
    }
    version = 1
}

$bookmarks | ConvertTo-Json -Depth 50 | Set-Content $bookmarksPath -Encoding UTF8

# --- 5. Brave als Default-Browser setzen (nur Hinweis) ---------
Write-Host "PC Setup fertig."
Write-Host "Brave einmal manuell als Standardbrowser bestaetigen:" -ForegroundColor Yellow
Write-Host "  Settings -> Apps -> Default apps -> Brave"
