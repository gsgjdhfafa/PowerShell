#requires -Version 5.1
<#
  Liest den Inhalt der via $args[0] uebergebenen Datei und legt ihn als Text
  ins Clipboard. Unterstuetzt:
    - .pdf            via pdftotext (Poppler) wenn auf PATH, sonst Word-COM
    - .docx, .docm    via ZIP+XML (pure .NET, kein Office noetig)
    - .xlsx, .xlsm    via ZIP+XML (Shared-Strings + Sheet1)
    - .pptx           via ZIP+XML (Slide-Texte)
    - .txt, .md, .json, .ps1, .py, .csv, .log, .xml, .yaml, .yml,
      .html, .htm, .ini, .conf, .toml, .sh, .ahk    via Get-Content -Raw
    - alles andere    Fehlermeldung ins Clipboard

  Aufruf (aus zf-hotkeys.ahk):
    powershell -NoProfile -WindowStyle Hidden -File extract-content.ps1 "<path>"
#>

param(
    [Parameter(Mandatory)] [string] $Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms          -ErrorAction SilentlyContinue

function Set-ClipText([string]$Text) {
    [System.Windows.Forms.Clipboard]::SetText($Text)
}

function Notify([string]$Text) {
    [System.Windows.Forms.Clipboard]::SetText($Text)
}

if (-not (Test-Path -LiteralPath $Path)) {
    Set-ClipText "extract-content: Datei nicht gefunden: $Path"
    exit 1
}

$ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()

# --- 1. Text-Dateien (alles was lesbar ist) --------------------------------
$textExt = @(
    '.txt','.md','.json','.ps1','.psm1','.py','.csv','.log','.xml',
    '.yaml','.yml','.html','.htm','.ini','.conf','.toml','.sh','.ahk',
    '.js','.ts','.tsx','.jsx','.css','.scss','.go','.rs','.java','.c',
    '.h','.cpp','.hpp','.cs','.rb','.lua','.sql','.env','.gitignore'
)
if ($textExt -contains $ext) {
    Set-ClipText (Get-Content -Raw -LiteralPath $Path)
    exit 0
}

# --- 2. PDF via pdftotext / Word-COM ---------------------------------------
function Extract-Pdf([string]$p) {
    $pdftotext = Get-Command 'pdftotext.exe' -ErrorAction SilentlyContinue
    if ($pdftotext) {
        $tmp = [IO.Path]::Combine([IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString() + '.txt')
        & $pdftotext.Source -layout -enc UTF-8 -- $p $tmp 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tmp)) {
            $t = Get-Content -Raw -LiteralPath $tmp
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            return $t
        }
    }
    # Fallback: Word-COM (PDF-Import seit Word 2013)
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open($p, [Type]::Missing, $true)  # ReadOnly
        $txt = $doc.Content.Text
        $doc.Close($false)
        $word.Quit()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        return $txt
    } catch {
        return "extract-content: PDF nicht lesbar (pdftotext fehlt UND kein Word installiert): $p"
    }
}

# --- 3. DOCX/DOCM via ZIP+XML ----------------------------------------------
function Extract-Docx([string]$p) {
    $zip = [IO.Compression.ZipFile]::OpenRead($p)
    try {
        $entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' } | Select-Object -First 1
        if (-not $entry) { return "extract-content: docx hat kein word/document.xml: $p" }
        $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
        $xml = $reader.ReadToEnd()
        $reader.Dispose()
        # Absatz-Trenner: <w:p> -> Newline. Tab: <w:tab/>. Rest: Tags strippen.
        $xml = $xml -replace '<w:tab[^/]*/>', "`t"
        $xml = $xml -replace '<w:br[^/]*/>',  "`n"
        $xml = $xml -replace '</w:p>',         "`n"
        $xml = $xml -replace '<[^>]+>', ''
        # XML-Entities zurueck
        $xml = $xml -replace '&amp;', '&'
        $xml = $xml -replace '&lt;',  '<'
        $xml = $xml -replace '&gt;',  '>'
        $xml = $xml -replace '&quot;','"'
        $xml = $xml -replace '&apos;',"'"
        return $xml
    } finally {
        $zip.Dispose()
    }
}

# --- 4. XLSX/XLSM via ZIP+XML (sharedStrings + sheet1) ---------------------
function Extract-Xlsx([string]$p) {
    $zip = [IO.Compression.ZipFile]::OpenRead($p)
    try {
        $shared = @()
        $ss = $zip.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' } | Select-Object -First 1
        if ($ss) {
            $r = New-Object IO.StreamReader($ss.Open(), [Text.Encoding]::UTF8)
            $ssXml = [xml]$r.ReadToEnd(); $r.Dispose()
            # InnerText konkateniert alle Text-Knoten unter <si> -> deckt Rich-Text-Runs (<r><t>...</t></r>) automatisch ab
            $shared = @($ssXml.sst.si | ForEach-Object { $_.InnerText })
        }
        $sheets = $zip.Entries | Where-Object { $_.FullName -match '^xl/worksheets/sheet\d+\.xml$' } | Sort-Object FullName
        $out = New-Object System.Text.StringBuilder
        foreach ($sh in $sheets) {
            $r = New-Object IO.StreamReader($sh.Open(), [Text.Encoding]::UTF8)
            $shXml = [xml]$r.ReadToEnd(); $r.Dispose()
            [void]$out.AppendLine("# " + $sh.FullName)
            foreach ($row in $shXml.worksheet.sheetData.row) {
                $cells = @()
                foreach ($c in $row.c) {
                    $v = $c.v
                    if ($c.t -eq 's' -and $v -ne $null) { $v = $shared[[int]$v] }
                    $cells += $v
                }
                [void]$out.AppendLine(($cells -join "`t"))
            }
        }
        return $out.ToString()
    } finally {
        $zip.Dispose()
    }
}

# --- 5. PPTX via ZIP+XML (alle Slides) -------------------------------------
function Extract-Pptx([string]$p) {
    $zip = [IO.Compression.ZipFile]::OpenRead($p)
    try {
        $slides = $zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' } | Sort-Object FullName
        $out = New-Object System.Text.StringBuilder
        foreach ($s in $slides) {
            $r = New-Object IO.StreamReader($s.Open(), [Text.Encoding]::UTF8)
            $xml = $r.ReadToEnd(); $r.Dispose()
            $xml = $xml -replace '</a:p>', "`n"
            $xml = $xml -replace '<[^>]+>', ''
            $xml = $xml -replace '&amp;', '&' -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"' -replace '&apos;',"'"
            [void]$out.AppendLine("# " + $s.FullName)
            [void]$out.AppendLine($xml.Trim())
        }
        return $out.ToString()
    } finally {
        $zip.Dispose()
    }
}

# --- 6. Dispatch -----------------------------------------------------------
switch ($ext) {
    '.pdf'  { Set-ClipText (Extract-Pdf  $Path); break }
    '.docx' { Set-ClipText (Extract-Docx $Path); break }
    '.docm' { Set-ClipText (Extract-Docx $Path); break }
    '.xlsx' { Set-ClipText (Extract-Xlsx $Path); break }
    '.xlsm' { Set-ClipText (Extract-Xlsx $Path); break }
    '.pptx' { Set-ClipText (Extract-Pptx $Path); break }
    default {
        # Letzter Versuch: als Text lesen. Wenn das BOM-haftig wird -> raw bytes als Hex-Vorschau ist hier zu viel.
        try {
            Set-ClipText (Get-Content -Raw -LiteralPath $Path)
        } catch {
            Set-ClipText "extract-content: unbekannter/binaerer Typ '$ext' fuer $Path"
            exit 2
        }
    }
}
