#Requires -Version 5.1
<#
Dedupe-and-version: scans the currently active Explorer folder for content-hash
duplicates and moves all but the newest copy into
  C:\Users\Admin\Documents\SOT_MASTER_LIVE\_Versions\<timestamp>\<orig-relpath>\
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SotMain     = 'C:\Users\Admin\Documents\SOT_MASTER_LIVE'
$VersionsDir = Join-Path $SotMain '_Versions'

Add-Type -AssemblyName System.Windows.Forms

# --- 1. Aktives Explorer-Fenster ermitteln ---------------------------------
function Get-ActiveExplorerPath {
    $shell = New-Object -ComObject Shell.Application
    Add-Type -Name W -Namespace ZF -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern System.IntPtr GetForegroundWindow();
'@ -ErrorAction SilentlyContinue
    $fg = [ZF.W]::GetForegroundWindow()
    foreach ($w in $shell.Windows()) {
        try {
            if ([IntPtr]$w.HWND -eq $fg) {
                return $w.Document.Folder.Self.Path
            }
        } catch { }
    }
    return $null
}

$folder = Get-ActiveExplorerPath
if (-not $folder -or -not (Test-Path -LiteralPath $folder)) {
    [System.Windows.Forms.MessageBox]::Show('Kein Explorer-Fenster aktiv.', 'ZF dedup') | Out-Null
    exit 1
}

# --- 2. Dateien einsammeln -------------------------------------------------
$files = @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue)
if ($files.Count -lt 2) {
    [System.Windows.Forms.MessageBox]::Show("Nichts zu tun in:`n$folder", 'ZF dedup') | Out-Null
    exit 0
}

# --- 3. Hash + Gruppieren --------------------------------------------------
$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$runDir    = Join-Path $VersionsDir $stamp
$relSource = ($folder -replace '^[A-Za-z]:\\', '') -replace '[\\/]+$', ''
$target    = Join-Path $runDir $relSource

$dupGroups = $files |
    ForEach-Object {
        [PSCustomObject]@{
            File = $_
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    } |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 }

if (-not $dupGroups) {
    [System.Windows.Forms.MessageBox]::Show("Keine Duplikate in:`n$folder", 'ZF dedup') | Out-Null
    exit 0
}

# --- 4. Aeltere Kopien wegversionieren -------------------------------------
if (-not (Test-Path -LiteralPath $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

$moved = 0
foreach ($grp in $dupGroups) {
    $keep = $grp.Group | Sort-Object { $_.File.LastWriteTime } -Descending | Select-Object -First 1
    foreach ($item in $grp.Group) {
        if ($item.File.FullName -eq $keep.File.FullName) { continue }
        $dest = Join-Path $target $item.File.Name
        $n = 1
        while (Test-Path -LiteralPath $dest) {
            $base = [IO.Path]::GetFileNameWithoutExtension($item.File.Name)
            $ext  = [IO.Path]::GetExtension($item.File.Name)
            $dest = Join-Path $target ("{0}__{1}{2}" -f $base, $n, $ext)
            $n++
        }
        Move-Item -LiteralPath $item.File.FullName -Destination $dest -Force
        $moved++
    }
}

[System.Windows.Forms.MessageBox]::Show(
    "$moved Duplikate verschoben nach:`n$target",
    'ZF dedup') | Out-Null
