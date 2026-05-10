#requires -Version 5.1
<#
  Tastatur reparieren:
    - Layout auf Deutsch (DE-DE) setzen, andere entfernen
    - Sticky Keys + Filter Keys + Toggle Keys aus
    - Num Lock einschalten (manche Laptops mappen Num auf Pfeiltasten)
  Idempotent. User-Scope (kein Admin).
  Aufruf:
    powershell -ExecutionPolicy Bypass -File .\fix-keyboard.ps1
#>

$ErrorActionPreference = 'Stop'

# --- 1. Keyboard-Layout: Deutsch DE-DE als einziges -------------------------
# 0407:00000407 = German (Germany) Standard.
$lang = New-WinUserLanguageList -Language de-DE
$lang[0].InputMethodTips.Clear()
$lang[0].InputMethodTips.Add('0407:00000407')
Set-WinUserLanguageList -LanguageList $lang -Force
Set-WinDefaultInputMethodOverride -InputTip '0407:00000407'
Write-Host '[ok] Layout = Deutsch (DE-DE)'

# --- 2. Accessibility-Stoerer ausschalten -----------------------------------
function Set-Reg($Path, $Name, $Value) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
}

# Sticky Keys aus + Aktivierungs-Hotkey aus
Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys'         'Flags' '506'
# Toggle Keys (piept bei Caps/Num/Scroll) aus
Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys'         'Flags' '58'
# Filter Keys (ignoriert kurze/wiederholte Tasten) aus  <-- fixt Pfeiltasten oft
Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response'  'Flags' '122'
Write-Host '[ok] Sticky/Filter/Toggle Keys aus'

# --- 3. Num Lock anschalten (jetzt + nach Reboot) ---------------------------
# Aktuell:
$wsh = New-Object -ComObject WScript.Shell
# Nur druecken wenn nicht schon an, sonst toggelt es aus.
Add-Type -Name K -Namespace W -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern short GetKeyState(int key);
"@
$numOn = ([W.K]::GetKeyState(0x90) -band 1) -eq 1
if (-not $numOn) { $wsh.SendKeys('{NUMLOCK}') }
# Beim naechsten Login auch:
Set-Reg 'HKCU:\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2'
Write-Host '[ok] Num Lock an'

# --- 4. Tastatur-Treiber kurz neu zuweisen (greift den Layout-Wechsel ab) ---
# Setzt den aktiven Input fuer die laufende Sitzung explizit.
Add-Type -Name H -Namespace W -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern uint LoadKeyboardLayout(string KLID, uint Flags);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool PostMessage(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, System.IntPtr lParam);
"@
$KLF_ACTIVATE = 1
[void][W.H]::LoadKeyboardLayout('00000407', $KLF_ACTIVATE)

Write-Host ''
Write-Host '[done] Tastatur gefixt.'
Write-Host '       Test:  @ via AltGr+Q'
Write-Host '              Pfeiltasten direkt'
Write-Host '       Falls noch komisch: einmal ab- und wieder anmelden.'
