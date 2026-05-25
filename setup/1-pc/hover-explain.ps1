#requires -Version 5.1
<#
  Ollama-Hover-Explain: bekommt Window-Titel + Klassen-Name + Kontrollname,
  fragt lokale Ollama-API nach einer kurzen Deutsch-Erklaerung, zeigt sie
  als BalloonTip im Tray. Fallback wenn Ollama nicht erreichbar: Google-Tab
  im Default-Browser.

  Aufruf (aus zf-hotkeys.ahk):
    powershell -NoProfile -WindowStyle Hidden -File hover-explain.ps1 `
      -Title "..." -Class "..." -Control "..."

  ENV (optional):
    ZF_OLLAMA_URL    Default: http://localhost:11434
    ZF_OLLAMA_MODEL  Default: llama3.2:3b
#>

param(
    [string]$Title   = '',
    [string]$Class   = '',
    [string]$Control = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing       -ErrorAction SilentlyContinue

$base  = if ($env:ZF_OLLAMA_URL)   { $env:ZF_OLLAMA_URL }   else { 'http://localhost:11434' }
$model = if ($env:ZF_OLLAMA_MODEL) { $env:ZF_OLLAMA_MODEL } else { 'llama3.2:3b' }

# --- 1. Balloon-Helper -----------------------------------------------------
function Show-Balloon([string]$Title, [string]$Text, [int]$Ms = 6000) {
    $icon = New-Object System.Windows.Forms.NotifyIcon
    $icon.Icon = [System.Drawing.SystemIcons]::Information
    $icon.Visible = $true
    $icon.BalloonTipTitle = $Title
    $icon.BalloonTipText  = $Text
    $icon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
    $icon.ShowBalloonTip($Ms)
    Start-Sleep -Milliseconds ($Ms + 500)
    $icon.Visible = $false
    $icon.Dispose()
}

# --- 2. Fallback Google ----------------------------------------------------
function Open-GoogleFallback {
    $q = [System.Uri]::EscapeDataString("$Class windows control")
    Start-Process "https://www.google.com/search?q=$q"
}

# --- 3. Ollama-Call --------------------------------------------------------
$prompt = @"
Du bist ein knapper Windows-Coach. Antworte auf Deutsch in maximal 60 Worten.
Erklaer dem Nutzer, was er hier vor sich hat und was er sinnvoll machen kann.

Fenster-Titel : $Title
Window-Klasse : $Class
Kontroll-Name : $Control
"@

$body = @{
    model  = $model
    prompt = $prompt
    stream = $false
    options = @{ temperature = 0.2; num_predict = 200 }
} | ConvertTo-Json -Depth 4

try {
    $resp = Invoke-RestMethod -Uri "$base/api/generate" -Method Post -Body $body `
        -ContentType 'application/json' -TimeoutSec 12
    $text = $resp.response
    if (-not $text -or $text.Trim() -eq '') {
        throw 'Leere Antwort'
    }
    Show-Balloon "ZF Hover ($Class)" $text.Trim()
} catch {
    # Ollama unerreichbar oder kaputt -> Google
    Show-Balloon "ZF Hover (Ollama offline)" "Oeffne Google fuer: $Class"
    Open-GoogleFallback
}
