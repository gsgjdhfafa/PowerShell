#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")
SetWorkingDir(A_ScriptDir)

; ============================================================================
; ZF Global Hotkeys — Phase 4
; Prefix Alt+Ctrl + <key>, plus standalone Ctrl+^ for window tiling.
; ============================================================================

global SOT_MAIN     := "C:\Users\Admin\Documents\SOT_MASTER_LIVE"
global EVERYTHING   := "C:\Program Files\Everything\Everything.exe"
global AREAS        := ["1-Pitch", "2-Bewerbung", "3-Insolvenz", "4-Betreuung"]
global VERSIONS_DIR := SOT_MAIN . "\_Versions"

EnsureDir(SOT_MAIN)
for a in AREAS
    EnsureDir(SOT_MAIN . "\" . a)
EnsureDir(SOT_MAIN . "\Autorun")
EnsureDir(VERSIONS_DIR)

; ---- Hotkeys ---------------------------------------------------------------
^!q::Run(EVERYTHING)
^!w::Where()
^!e::ExplorerLastHour()
^!a::ContentToClip()
^!s::SaveToSOT()
^!d::Run("ms-settings:powersleep")
^!f::Run(EVERYTHING)
^!g::OpenAreas()
^!y::HoverExplain()
^!x::Run('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' A_ScriptDir '\dedup-and-version.ps1"')
^!p::Send("#+s")
^!v::Send("#!r")
^!b::Send("^z")
^SC029::TileAllWindows()
^vkDD::TileAllWindows()
^F12::TileAllWindows()

; ---- Functions -------------------------------------------------------------
EnsureDir(p) {
    if !DirExist(p)
        DirCreate(p)
}

Where() {
    IB := InputBox("Datei-Pattern (z.B. *.pdf, *bahn*)", "ZF where", "w320 h120")
    if (IB.Result = "OK" && IB.Value != "")
        Run(EVERYTHING . ' -s "' . IB.Value . '"')
}

ExplorerLastHour() {
    Run('explorer.exe "search-ms:displayname=Letzte%20Stunde&query=System.DateModified:today&"')
}

GetSelectedExplorerPath() {
    shell := ComObject("Shell.Application")
    activeHwnd := WinExist("A")
    for w in shell.Windows() {
        try {
            if (w.HWND = activeHwnd) {
                sel := w.Document.SelectedItems
                if (sel.Count > 0)
                    return sel.Item(0).Path
            }
        }
    }
    return ""
}

ContentToClip() {
    p := GetSelectedExplorerPath()
    if (p = "") {
        ToolTip("Keine Datei im Explorer markiert")
        SetTimer(() => ToolTip(), -2500)
        return
    }
    cmd := '$p=''' p ''';if(Test-Path -LiteralPath $p){Set-Clipboard -Value (Get-Content -Raw -LiteralPath $p)}'
    Run('powershell -NoProfile -WindowStyle Hidden -Command "' cmd '"', , "Hide")
}

SaveToSOT() {
    p := GetSelectedExplorerPath()
    if (p != "") {
        cmd := 'Copy-Item -LiteralPath ''' p ''' -Destination ''' SOT_MAIN ''' -Force'
        Run('powershell -NoProfile -WindowStyle Hidden -Command "' cmd '"', , "Hide")
    }
    Run('explorer.exe "' SOT_MAIN '"')
}

OpenAreas() {
    for a in AREAS
        Run('explorer.exe "' SOT_MAIN '\' a '"')
}

HoverExplain() {
    MouseGetPos(&mx, &my, &winId, &ctlName)
    title := ""
    cls := ""
    try title := WinGetTitle("ahk_id " winId)
    try cls := WinGetClass("ahk_id " winId)
    txt := "Fenster: " title "`nKlasse: " cls "`nKontrolle: " ctlName "`nPos: " mx "," my
    ToolTip(txt, mx + 16, my + 16)
    SetTimer(() => ToolTip(), -6000)
    if (cls != "")
        Run('https://www.google.com/search?q=' . cls . '+windows+control')
}

TileAllWindows() {
    monCount := MonitorGetCount()
    windows := []
    for hwnd in WinGetList() {
        try {
            if (WinGetMinMax("ahk_id " hwnd) = -1)
                continue
            t := WinGetTitle("ahk_id " hwnd)
            if (t = "")
                continue
            cls := WinGetClass("ahk_id " hwnd)
            if RegExMatch(cls, "i)^(Shell_TrayWnd|Progman|WorkerW|Windows\.UI\.Core\.CoreWindow)$")
                continue
            windows.Push(hwnd)
        }
    }
    if (windows.Length = 0)
        return
    perMon := Ceil(windows.Length / monCount)
    idx := 0
    Loop monCount {
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        w := R - L, h := B - T
        cells := Min(perMon, windows.Length - idx)
        if (cells <= 0)
            break
        cols := Ceil(Sqrt(cells))
        rows := Ceil(cells / cols)
        cw := w // cols, ch := h // rows
        Loop cells {
            i := A_Index - 1
            col := Mod(i, cols)
            row := i // cols
            try {
                idx += 1
                hwnd := windows[idx]
                WinRestore("ahk_id " hwnd)
                WinMove(L + col * cw, T + row * ch, cw, ch, "ahk_id " hwnd)
            }
        }
    }
}
