#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO Control Center - START (Meilenstein 1)
# ============================================================
#  1. Legt die Ordnerstruktur unter PicoSetup an (loescht nichts)
#  2. Prueft, ob ADB vorhanden ist
#  3. Prueft, ob eine PICO per ADB sichtbar ist
#  4. Startet optional scrcpy (Live-Fenster), falls vorhanden
#  5. Klare Statusmeldungen
#  6. KEINE riskanten Aenderungen, installiert nichts, loescht nichts
#
#  Start: Doppelklick, oder:  python START_PICO_CONTROL_CENTER.py
# ============================================================

import os, sys, shutil, subprocess
from pathlib import Path

def base_dir() -> Path:
    here = Path(__file__).resolve().parent
    if here.name.lower() == "picosetup":
        return here
    return Path.home() / "PicoSetup"

BASE = base_dir()

FOLDERS = [
    "00_START_HERE",
    "01_TOOLS/adb", "01_TOOLS/scrcpy", "01_TOOLS/yt-dlp",
    "02_APPS/APPS_TO_TEST", "02_APPS/APPS_APPROVED", "02_APPS/APPS_REJECTED", "02_APPS/APP_REPORTS",
    "03_MEDIA/DOWNLOADS_PC", "03_MEDIA/TO_PICO", "03_MEDIA/FROM_PICO",
    "04_BACKUP_CLONE/FROM_PICO", "04_BACKUP_CLONE/TO_PICO",
    "05_WORK_SETUP",
    "99_REPORTS_LOGS",
]

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")

def make_folders():
    print("\n[1/4] Ordnerstruktur")
    created, existed = 0, 0
    for rel in FOLDERS:
        p = BASE / rel
        if p.exists(): existed += 1
        else: p.mkdir(parents=True, exist_ok=True); created += 1
    ok(f"Struktur bereit unter: {BASE}")
    info(f"{created} neu angelegt, {existed} waren schon da (nichts geloescht).")
    readme = BASE / "00_START_HERE" / "LIES_MICH.txt"
    if not readme.exists():
        readme.write_text(
            "PICO Control Center\n===================\n\n"
            "Start immer ueber: START_PICO_CONTROL_CENTER.py\n"
            "Menue/Modifikation: PICO_CONTROL_CENTER.py\n"
            "Kopie ins Netzwerk:  SYNC_TO_SHARED.py\n",
            encoding="utf-8")
        ok("Orientierung geschrieben: 00_START_HERE/LIES_MICH.txt")

def find_adb():
    exe = "adb.exe" if os.name == "nt" else "adb"
    p = shutil.which("adb")
    if p: return p
    local = BASE / "01_TOOLS" / "adb" / exe
    if local.exists(): return str(local)
    if os.name == "nt":
        wg = Path(os.environ.get("LOCALAPPDATA","")) / "Microsoft" / "WinGet" / "Links" / "adb.exe"
        if wg.exists(): return str(wg)
    return None

def find_scrcpy():
    p = shutil.which("scrcpy")
    if p: return p
    exe = "scrcpy.exe" if os.name == "nt" else "scrcpy"
    local = BASE / "01_TOOLS" / "scrcpy" / exe
    if local.exists(): return str(local)
    return None

def run(cmd, timeout=20):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

def check_adb():
    print("\n[2/4] ADB (Android Debug Bridge)")
    adb = find_adb()
    if not adb:
        bad("ADB nicht gefunden.")
        info("Kostenlos holen (eine Variante reicht):")
        info("  A) Windows:  winget install Google.PlatformTools")
        info("  B) Portable: 'platform-tools' entpacken nach 01_TOOLS\\adb\\")
        return None
    ok(f"ADB gefunden: {adb}")
    code, out = run([adb, "version"])
    if code == 0 and out.strip():
        info(out.strip().splitlines()[0])
    return adb

def check_device(adb):
    print("\n[3/4] PICO-Verbindung")
    if not adb: warn("Uebersprungen (kein ADB)."); return False
    run([adb, "start-server"])
    _, out = run([adb, "devices"])
    devices = []
    for l in out.splitlines():
        l = l.strip()
        if "\t" in l:
            serial, state = l.split("\t", 1)
            devices.append((serial.strip(), state.strip()))
    if not devices:
        bad("Keine PICO sichtbar.")
        info("  - USB-Kabel muss ein DATEN-Kabel sein")
        info("  - Brille: Entwickleroptionen -> USB-Debugging AN")
        info("  - Popup 'USB-Debugging zulassen' bestaetigen")
        return False
    all_ok = False
    for serial, state in devices:
        if state == "device": ok(f"PICO verbunden: {serial}"); all_ok = True
        elif state == "unauthorized": warn(f"{serial}: nicht autorisiert - Popup bestaetigen.")
        elif state == "offline": warn(f"{serial}: offline - Kabel neu einstecken.")
        else: warn(f"{serial}: Status '{state}'")
    if all_ok:
        _, model = run([adb, "shell", "getprop", "ro.product.model"])
        _, bat = run([adb, "shell", "dumpsys", "battery"])
        lvl = next((l.split("level:")[1].strip() for l in bat.splitlines() if "level:" in l), "")
        info(f"Modell: {model.strip()}   Akku: {lvl}%")
    return all_ok

def maybe_scrcpy(adb, connected):
    print("\n[4/4] Live-Fenster (scrcpy, optional)")
    scr = find_scrcpy()
    if not scr:
        warn("scrcpy nicht gefunden (optional, kostenlos).")
        info("Spaeter: 'scrcpy' entpacken nach 01_TOOLS\\scrcpy\\")
        return
    ok(f"scrcpy gefunden: {scr}")
    if not connected: info("Keine PICO verbunden - Start uebersprungen."); return
    try: answer = input("        Live-Fenster jetzt oeffnen? [j/N] ").strip().lower()
    except EOFError: answer = "n"
    if answer in ("j","ja","y","yes"):
        try: subprocess.Popen([scr]); ok("scrcpy gestartet.")
        except Exception as e: bad(f"Start fehlgeschlagen: {e}")
    else: info("Uebersprungen.")

def main():
    print("-"*60); print("  PICO CONTROL CENTER  -  Start / Statuscheck"); print("-"*60)
    make_folders()
    adb = check_adb()
    connected = check_device(adb)
    maybe_scrcpy(adb, connected)
    print("\n" + "="*60); print("  ZUSAMMENFASSUNG"); print("="*60)
    ok("Ordnerstruktur steht.")
    (ok if adb else bad)("ADB " + ("bereit." if adb else "fehlt - siehe oben."))
    (ok if connected else warn)("PICO " + ("verbunden." if connected else "nicht verbunden - siehe Checkliste."))
    print("\n  Naechster Schritt:")
    if not adb: info("ADB installieren, dann Skript erneut starten.")
    elif not connected: info("USB-Debugging bestaetigen, dann erneut starten.")
    else: info("Alles gruen -> PICO_CONTROL_CENTER.py fuer das Menue.")
    print()
    try: input("  [Enter] zum Schliessen ...")
    except EOFError: pass

if __name__ == "__main__":
    main()
