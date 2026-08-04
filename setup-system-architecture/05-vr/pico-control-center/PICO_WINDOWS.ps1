# ============================================================
#  PICO 1-Klick (Windows)  -  verbinden + kluge Apps + Zugaenge
#  Nutzung (PowerShell-Fenster):
#     powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\PICO_WINDOWS.ps1"
#  Installiert nur, loescht nichts. Aendert keine VR-Aufloesung.
# ============================================================
$ErrorActionPreference = 'Continue'
Write-Host "============================================================"
Write-Host "  PICO 1-KLICK (Windows)"
Write-Host "============================================================"

$Home4U = Join-Path $HOME 'PicoSetup'
$ApkTmp = Join-Path $env:TEMP 'pico_apks'
New-Item -ItemType Directory -Force -Path $Home4U, $ApkTmp | Out-Null

# --- 1) ADB sicherstellen -----------------------------------
function Resolve-Adb {
    $c = Get-Command adb -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\adb.exe'),
        (Join-Path $HOME 'platform-tools\adb.exe'),
        (Join-Path $Home4U '01_TOOLS\adb\adb.exe'))) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

$Adb = Resolve-Adb
if (-not $Adb) {
    Write-Host "[*] ADB nicht gefunden - versuche winget ..."
    try {
        winget install --id Google.PlatformTools -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    } catch {}
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    $Adb = Resolve-Adb
}
if (-not $Adb) {
    Write-Host "[*] Lade Platform-Tools direkt ..."
    try {
        $zip = Join-Path $env:TEMP 'platform-tools.zip'
        Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $HOME -Force
        $Adb = Join-Path $HOME 'platform-tools\adb.exe'
    } catch { Write-Host "[X] Download fehlgeschlagen: $($_.Exception.Message)" }
}
if (-not $Adb -or -not (Test-Path $Adb)) {
    Write-Host "[X] ADB konnte nicht bereitgestellt werden."
    Read-Host "[Enter] zum Schliessen"; return
}
Write-Host "[OK] ADB: $Adb"

# --- 2) Verbinden -------------------------------------------
& $Adb kill-server  2>$null | Out-Null
& $Adb start-server 2>$null | Out-Null
Write-Host "[*] Warte auf die Brille ... (Popup 'USB-Debugging zulassen' IM Headset bestaetigen)"
$state = ''
for ($i = 0; $i -lt 25; $i++) {
    $lines = (& $Adb devices) 2>$null
    $dev = $lines | Where-Object { $_ -match "`t" } | Select-Object -First 1
    if ($dev -match "`tdevice$")      { $state = 'device'; break }
    if ($dev -match "`tunauthorized") { Write-Host "    -> Bitte Popup im Headset bestaetigen ..." }
    Start-Sleep -Seconds 2
}
if ($state -ne 'device') {
    Write-Host "[X] Keine autorisierte Pico gefunden."
    Write-Host "    Pruefe: DATENkabel (nicht nur laden)? Popup im Headset bestaetigt? Direkt am PC ohne Hub?"
    & $Adb devices
    Read-Host "[Enter] zum Schliessen"; return
}
$model = (& $Adb shell getprop ro.product.model) -join '' 
Write-Host "[OK] Verbunden: $($model.Trim())"

# --- 3) Kuratierte Apps -------------------------------------
function Get-GitHubApk {
    param($Repo, $Match)
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'PICO' } -TimeoutSec 25
        $a = $rel.assets | Where-Object { $_.name -match '\.apk$' -and $_.name -match $Match } | Select-Object -First 1
        if (-not $a) { $a = $rel.assets | Where-Object { $_.name -match '\.apk$' } | Select-Object -First 1 }
        if ($a) { return $a.browser_download_url }
    } catch {}
    return $null
}
function Install-App {
    param($Name, $Pkg, $Url)
    $have = (& $Adb shell pm list packages $Pkg) | ForEach-Object { $_.Trim() }
    if ($have -contains "package:$Pkg") { Write-Host "  [OK] $Name: schon installiert"; return }
    if (-not $Url) { Write-Host "  [!] $Name: keine URL gefunden"; return }
    $apk = Join-Path $ApkTmp "$Name.apk"
    try {
        Write-Host "  [*] Lade $Name ..."
        Invoke-WebRequest -Uri $Url -OutFile $apk -UseBasicParsing -TimeoutSec 180
    } catch { Write-Host "  [X] $Name: Download-Fehler"; return }
    $out = (& $Adb install -r $apk) -join "`n"
    if ($out -match 'Success') { Write-Host "  [OK] $Name: installiert" }
    else { Write-Host "  [X] $Name: $($out.Trim())" }
}
Write-Host "--- Apps installieren ---"
Install-App 'Telegram' 'org.telegram.messenger' 'https://telegram.org/dl/android/apk'
Install-App 'VLC'      'org.videolan.vlc'       'https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk'
Install-App 'Brave'    'com.brave.browser'      (Get-GitHubApk 'brave/brave-browser' 'arm64|universal')
Install-App 'Wolvic'   'com.igalia.wolvic'      (Get-GitHubApk 'Igalia/wolvic' 'arm64|noapi')

# --- 4) Login-/Dashboard-Seiten -----------------------------
Write-Host "--- Login-/Dashboard-Seiten auf der Brille oeffnen ---"
foreach ($u in @(
    'https://www.notion.so/login',
    'https://mail.google.com',
    'https://calendar.google.com',
    'https://tasks.google.com',
    'https://web.telegram.org')) {
    & $Adb shell am start -a android.intent.action.VIEW -d $u 2>$null | Out-Null
    Write-Host "  offen: $u"
}

Write-Host "============================================================"
Write-Host "  FERTIG - jetzt in der Brille:"
Write-Host "   1. Telegram -> einloggen -> /start an deinen Bot"
Write-Host "      -> Mikro-Button = Voice-Diktat -> landet in Notion"
Write-Host "   2. Browser: 5 Tabs sind offen -> einloggen -> Lesezeichen setzen"
Write-Host "   3. Multi-Monitor: PICO Connect am PC starten"
Write-Host "============================================================"
Read-Host "[Enter] zum Schliessen"
