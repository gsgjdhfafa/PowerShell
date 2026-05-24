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

function Get-ActiveExplorerPath {
    $shell = New-Object -ComObject Shell.Application
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class W {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@ -ErrorAction SilentlyContinue
    $fg = [W]::GetForegroundWindow()
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
    [System.Windows.Forms.MessageBox] | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show('Kein Explorer-Fenster aktiv.', 'ZF dedup') | Out-Null
    exit 1
}

$files = Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue
if (-not $files -or $files.Count -lt 2) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Nichts zu tun in:`n$folder", 'ZF dedup') | Out-Null
    exit 0
}

$stamp     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$runDir    = Join-Path $VersionsDir $stamp
$relSource = ($folder -replace '^[A-Za-z]:\\', '') -replace '[\\/]+$', ''
$target    = Join-Path $runDir $relSource
if (-not (Test-Path -LiteralPath $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

$moved = 0
$files |
    ForEach-Object {
        [PSCustomObject]@{
            File = $_
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    } |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        $keep = $_.Group | Sort-Object { $_.File.LastWriteTime } -Descending | Select-Object -First 1
        $_.Group |
            Where-Object { $_.File.FullName -ne $keep.File.FullName } |
            ForEach-Object {
                $dest = Join-Path $target $_.File.Name
                $n = 1
                while (Test-Path -LiteralPath $dest) {
                    $base = [IO.Path]::GetFileNameWithoutExtension($_.File.Name)
                    $ext  = [IO.Path]::GetExtension($_.File.Name)
                    $dest = Join-Path $target ("{0}__{1}{2}" -f $base, $n, $ext)
                    $n++
                }
                Move-Item -LiteralPath $_.File.FullName -Destination $dest -Force
                $moved++
            }
    }

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "$moved Duplikate verschoben nach:`n$target",
    'ZF dedup') | Out-Null
