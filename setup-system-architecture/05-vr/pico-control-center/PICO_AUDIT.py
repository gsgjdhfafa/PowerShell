#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO AUDIT  -  was laeuft, was muss weg, was muss drauf?
# ============================================================
#  Doppelklick oder:  python PICO_AUDIT.py
#  Reiner Scan (lesend). Aendert / loescht / friert NICHTS ein.
#  Empfehlungen zum Einfrieren -> PICO_CONTROL_CENTER.py Punkt 12.
# ============================================================

import os, shutil, subprocess, datetime, time
from pathlib import Path

def base_dir():
    here = Path(__file__).resolve().parent
    if here.name.lower() == "picosetup":
        return here
    return Path.home() / "PicoSetup"

BASE  = base_dir()
TOOLS = BASE / "01_TOOLS"
LOGS  = BASE / "99_REPORTS_LOGS"

# Gleiche Sperrliste wie PICO_CONTROL_CENTER.py - nie anfassen (Brick-Gefahr):
CRITICAL = ("launcher","systemui","com.android.","com.pico","com.pvr","com.picovr",
            "com.pvrsupport","vrshell","com.qualcomm","inputmethod",
            "com.google.android.gms","com.google.android.gsf","com.google.android.gsm",
            "telephony","packageinstaller","com.android.vending","provider","com.oplus",
            "com.bytedance.picovr","setup","keyguard","com.pico4")

# Unser kuratiertes Ziel-Setup (siehe DEPLOY_PICO.py / PICO_WINDOWS.ps1 etc.):
TARGETS = {
    "org.telegram.messenger": "Telegram (Voice -> Bot -> Notion)",
    "com.brave.browser":      "Brave (Dashboards/Bookmarks)",
    "org.videolan.vlc":       "VLC (Medien)",
    "com.igalia.wolvic":      "Wolvic (XR-Browser)",
}

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")
def stamp(): return datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
def is_critical(pkg): return any(k in pkg.lower() for k in CRITICAL)

def find_adb():
    exe = "adb.exe" if os.name == "nt" else "adb"
    p = shutil.which("adb")
    if p: return p
    local = TOOLS / "adb" / exe
    if local.exists(): return str(local)
    for cand in (
        Path.home() / "platform-tools" / exe,
        Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft" / "WinGet" / "Links" / exe,
    ):
        if cand.exists(): return str(cand)
    return None

def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

def device_ok(adb):
    if not adb: return False
    _, out = run([adb, "devices"])
    return any("\t" in l and l.strip().endswith("device") for l in out.splitlines())

def wait_for_device(adb, tries=15):
    if device_ok(adb): return True
    print("  [*] Warte auf die PICO (USB oder WLAN-ADB) ...")
    for _ in range(tries):
        if device_ok(adb): return True
        time.sleep(2)
    return False

def main():
    print("============================================================")
    print("  PICO AUDIT  -  installiert / laeuft / fehlt")
    print("============================================================")
    adb = find_adb()
    if not adb:
        bad("ADB fehlt. Erst START_PICO_CONTROL_CENTER.py oder PICO_WINDOWS.ps1 ausfuehren.")
        input("\n[Enter] zum Schliessen ..."); return
    if not wait_for_device(adb):
        bad("Keine autorisierte PICO gefunden (USB pruefen / Popup im Headset bestaetigen).")
        input("\n[Enter] zum Schliessen ..."); return

    _, model = run([adb, "shell", "getprop", "ro.product.model"])
    _, ver   = run([adb, "shell", "getprop", "ro.build.version.release"])
    _, df    = run([adb, "shell", "df", "-h", "/sdcard"])
    ok(f"{model.strip()}  Android {ver.strip()}")

    _, u = run([adb, "shell", "pm", "list", "packages", "-3"])
    user_pkgs = sorted(l.replace("package:", "").strip() for l in u.splitlines() if l.strip())
    _, s = run([adb, "shell", "pm", "list", "packages", "-s"])
    sys_pkgs = sorted(l.replace("package:", "").strip() for l in s.splitlines() if l.strip())
    all_pkgs = set(user_pkgs) | set(sys_pkgs)

    missing_targets = [p for p in TARGETS if p not in all_pkgs]
    present_targets  = [p for p in TARGETS if p in all_pkgs]
    candidates = [p for p in user_pkgs if p not in TARGETS and not is_critical(p)]
    crit       = sorted(p for p in all_pkgs if is_critical(p))
    sys_other  = sorted(p for p in sys_pkgs if not is_critical(p))

    lines = [f"PICO AUDIT  {stamp()}", f"Modell: {model.strip()}  Android: {ver.strip()}", "", df.strip()]
    def sec(t):
        lines.append(""); lines.append("=" * 60); lines.append(t); lines.append("=" * 60)

    print(f"\n--- [1] ZIEL-APPS (unser Setup) - {len(present_targets)}/{len(TARGETS)} vorhanden ---")
    sec(f"ZIEL-APPS - {len(present_targets)}/{len(TARGETS)} vorhanden")
    for p, name in TARGETS.items():
        vorhanden = p in all_pkgs
        line = f"  [{'OK' if vorhanden else 'X '}] {name:32s} ({p})"
        print(line); lines.append(line)

    print(f"\n--- [2] KANDIDATEN ZUM EINFRIEREN - {len(candidates)} App(s) ---")
    info("Von dir installiert, nicht Teil unseres Setups. Sicher pruefbar/umkehrbar")
    info("ueber PICO_CONTROL_CENTER.py -> Punkt 12 (friert ein, loescht nichts).")
    sec(f"KANDIDATEN ZUM EINFRIEREN ({len(candidates)})")
    if candidates:
        for p in candidates:
            print(f"    - {p}"); lines.append(f"  - {p}")
    else:
        print("    (keine - nichts Fremdes gefunden)")
        lines.append("  (keine)")

    print(f"\n--- [3] GESPERRT / KRITISCH - {len(crit)} System-Pakete (bleiben, Brick-Schutz) ---")
    sec(f"GESPERRT / KRITISCH ({len(crit)}) - bleiben unangetastet")
    lines += [f"  - {p}" for p in crit]

    sec(f"SONSTIGE SYSTEM-APPS ({len(sys_other)}) - Pico-eigen, nicht angefasst")
    lines += [f"  - {p}" for p in sys_other]

    LOGS.mkdir(parents=True, exist_ok=True)
    rep = LOGS / f"audit_{stamp()}.txt"
    rep.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n--- Report gespeichert: {rep} ---")

    print("\n--- Zusammenfassung ---")
    if missing_targets:
        warn(f"{len(missing_targets)} Ziel-App(s) fehlen: {', '.join(TARGETS[p] for p in missing_targets)}")
        info("Nachinstallieren: PICO_WINDOWS.ps1 / PICO_MAC.command / PICO_LINUX.sh erneut ausfuehren.")
    else:
        ok("Alle Ziel-Apps vorhanden.")
    if candidates:
        warn(f"{len(candidates)} Kandidat(en) zum Einfrieren -> PICO_CONTROL_CENTER.py, Punkt 12.")
    else:
        ok("Keine fremden User-Apps - nichts zum Aufraeumen.")

    input("\n[Enter] zum Schliessen ...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n  Abbruch.")
