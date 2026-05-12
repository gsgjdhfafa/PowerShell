#requires -Version 5.1
<#
  Telegram Desktop + WhatsApp Desktop + OpenClaw auf dem PC installieren.
  Idempotent. User-Scope (kein Admin noetig).
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\install-chat-apps.ps1

  Hinweis Telefonnummer:
    Telefonnummer fuer Telegram/WhatsApp wird beim ersten App-Start
    manuell eingegeben — sie kommt NICHT in irgendein Skript oder Repo.
#>

$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget fehlt. Windows Update ausfuehren, dann erneut.'
}

function Wg($id, $source = 'winget') {
    $present = winget list --id $id -e --source $source 2>$null
    if ($LASTEXITCODE -eq 0 -and ($present -match [regex]::Escape($id))) {
        Write-Host "[ok]   $id schon da"
        return
    }
    Write-Host "[..]   $id installieren ($source)"
    winget install --id $id -e --source $source --silent `
        --accept-source-agreements --accept-package-agreements | Out-Null
    Write-Host "[ok]   $id installiert"
}

# --- 1. Telegram Desktop -----------------------------------------------------
Wg 'Telegram.TelegramDesktop'

# --- 2. WhatsApp Desktop (Microsoft Store-Version) ---------------------------
# Die Store-Version ist die offizielle / am haeufigsten aktualisierte.
Wg '9NKSQGP7F2NH' 'msstore'

# --- 3. Ollama (falls noch nicht da) — Voraussetzung fuer OpenClaw -----------
Wg 'Ollama.Ollama'

# --- 4. PATH aktualisieren, damit `ollama` im aktuellen Fenster geht --------
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + `
            [Environment]::GetEnvironmentVariable('Path','User')

# --- 5. Hinweise zum naechsten Schritt --------------------------------------
Write-Host ''
Write-Host '[done] Installation fertig.'
Write-Host ''
Write-Host '== Erste Schritte =='
Write-Host '  Telegram Desktop  : Start-Menue -> Telegram -> Telefonnummer eingeben'
Write-Host '                      -> SMS-Code -> fertig.'
Write-Host '  WhatsApp Desktop  : Start-Menue -> WhatsApp -> QR-Code mit Handy scannen'
Write-Host '                      (Handy: Einstellungen -> Verknuepfte Geraete).'
Write-Host '  OpenClaw          : in einem neuen PowerShell-Fenster:'
Write-Host '                          ollama'
Write-Host '                      -> mit Pfeil "Launch OpenClaw (install)" anwaehlen'
Write-Host '                      -> Enter druecken -> der Installer laeuft.'
Write-Host '                      Alternativ direkt:  ollama launch openclaw'
Write-Host ''
Write-Host '== Sicherheits-Hinweis =='
Write-Host '  Telefonnummer kommt nirgends in Code oder Logs. Sie bleibt'
Write-Host '  ausschliesslich in den Apps selbst (Telegram/WhatsApp Account-Daten).'
