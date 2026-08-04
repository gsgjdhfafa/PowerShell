#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO_ALLES  -  EIN Skript, alle Systeme (Win / Mac / Linux)
# ============================================================
#  Start:
#     Windows:  python PICO_ALLES.py      (Python noetig)
#     Mac:      python3 PICO_ALLES.py
#  Pfade werden automatisch richtig gesetzt (Home-Ordner des Users).
#  Macht: ADB holen -> verbinden -> Apps installieren -> Login-Seiten oeffnen.
#  Installiert nur, loescht nichts, aendert keine VR-Aufloesung.
# ============================================================

import os, sys, platform, shutil, subprocess, time, json, re, zipfile, urllib.request
from pathlib import Path

OS   = platform.system()            # 'Windows' | 'Darwin' | 'Linux'
HOME = Path.home()
BASE = HOME / "PicoSetup"
APK  = BASE / "apks"
for d in (BASE, APK): d.mkdir(parents=True, exist_ok=True)

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")

def run(cmd, timeout=60):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

# --- ADB fuer das jeweilige System besorgen -----------------
PT_URL = {
    "Windows": "https://dl.google.com/android/repository/platform-tools-latest-windows.zip",
    "Darwin":  "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip",
    "Linux":   "https://dl.google.com/android/repository/platform-tools-latest-linux.zip",
}

def find_adb():
    p = shutil.which("adb")
    if p: return p
    exe = "adb.exe" if OS == "Windows" else "adb"
    cands = [HOME / "platform-tools" / exe]
    if OS == "Windows":
        cands.append(Path(os.environ.get("LOCALAPPDATA","")) / "Microsoft" / "WinGet" / "Links" / "adb.exe")
    for c in cands:
        if c.exists(): return str(c)
    return None

def ensure_adb():
    adb = find_adb()
    if adb: return adb
    if OS == "Windows":
        info("ADB nicht da - versuche winget ...")
        run(["winget","install","--id","Google.PlatformTools","-e","--silent",
             "--accept-package-agreements","--accept-source-agreements"], timeout=300)
        adb = find_adb()
        if adb: return adb
    # Direkt-Download (funktioniert ueberall)
    url = PT_URL.get(OS)
    if not url: return None
    try:
        info("Lade Platform-Tools (ADB) ...")
        zip_path = BASE / "platform-tools.zip"
        req = urllib.request.Request(url, headers={"User-Agent":"PICO"})
        with urllib.request.urlopen(req, timeout=180) as r, open(zip_path,"wb") as f:
            shutil.copyfileobj(r, f)
        with zipfile.ZipFile(zip_path) as z:
            z.extractall(HOME)
        exe = "adb.exe" if OS == "Windows" else "adb"
        adb = HOME / "platform-tools" / exe
        if OS != "Windows":
            try: os.chmod(adb, 0o755)
            except Exception: pass
        return str(adb) if adb.exists() else None
    except Exception as e:
        bad(f"ADB-Download fehlgeschlagen: {e}"); return None

def device_ok(adb):
    _, out = run([adb,"devices"])
    return any("\t" in l and l.strip().endswith("device") for l in out.splitlines())

def connect(adb):
    run([adb,"kill-server"]); run([adb,"start-server"])
    print("\n  Warte auf die Brille ... (Popup 'USB-Debugging zulassen' IM Headset bestaetigen)")
    for _ in range(25):
        _, out = run([adb,"devices"])
        line = next((l for l in out.splitlines() if "\t" in l), "")
        if line.strip().endswith("device"): return True
        if "unauthorized" in line: info("Bitte Popup im Headset bestaetigen ...")
        time.sleep(2)
    return False

# --- Apps --------------------------------------------------
CURATED = [
    ("Telegram","org.telegram.messenger","direct","https://telegram.org/dl/android/apk","Voice-Diktat -> Bot -> Notion"),
    ("VLC","org.videolan.vlc","direct","https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk","Medien / Fokus-Kino"),
    ("Brave","com.brave.browser","github","brave/brave-browser|arm64|universal","Dashboards Notion/Gmail/Kalender"),
    ("Wolvic","com.igalia.wolvic","github","Igalia/wolvic|arm64|noapi","XR-Browser (optional)"),
]
BOOKMARKS = ["https://www.notion.so/login","https://mail.google.com",
             "https://calendar.google.com","https://tasks.google.com","https://web.telegram.org"]

def gh_url(spec):
    repo, match = spec.split("|",1)
    try:
        req = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/latest", headers={"User-Agent":"PICO"})
        d = json.loads(urllib.request.urlopen(req, timeout=25).read().decode())
        apks = [a for a in d.get("assets",[]) if a["name"].endswith(".apk")]
        hit = next((a for a in apks if re.search(match.replace("|","|"), a["name"])), None) or (apks[0] if apks else None)
        return hit["browser_download_url"] if hit else None
    except Exception:
        return None

def install(adb, name, pkg, kind, spec, why):
    _, have = run([adb,"shell","pm","list","packages",pkg])
    have_lines = [l.strip() for l in have.splitlines()]
    if f"package:{pkg}" in have_lines: ok(f"{name}: schon da"); return
    url = spec if kind == "direct" else gh_url(spec)
    if not url: warn(f"{name}: keine URL"); return
    apk = APK / f"{name}.apk"
    try:
        info(f"Lade {name} ...")
        req = urllib.request.Request(url, headers={"User-Agent":"PICO"})
        with urllib.request.urlopen(req, timeout=180) as r, open(apk,"wb") as f:
            shutil.copyfileobj(r, f)
    except Exception as e:
        bad(f"{name}: Download-Fehler ({e})"); return
    _, out = run([adb,"install","-r",str(apk)], timeout=240)
    ok(f"{name}: installiert ({why})") if "Success" in out else bad(f"{name}: {out.strip()[:150]}")

def main():
    print("="*60); print(f"  PICO_ALLES  -  System: {OS}"); print("="*60)
    adb = ensure_adb()
    if not adb: bad("ADB nicht verfuegbar."); input("\n  [Enter] "); return
    ok(f"ADB: {adb}")
    if not connect(adb):
        bad("Keine autorisierte Pico gefunden.")
        info("DATENkabel (nicht nur laden)? Popup im Headset bestaetigt? Direkt am Rechner ohne Hub?")
        run([adb,"devices"]); input("\n  [Enter] "); return
    _, model = run([adb,"shell","getprop","ro.product.model"]); ok(f"Verbunden: {model.strip()}")

    print("\n--- Apps installieren ---")
    for name,pkg,kind,spec,why in CURATED: install(adb,name,pkg,kind,spec,why)

    print("\n--- Login-/Dashboard-Seiten auf der Brille oeffnen ---")
    for u in BOOKMARKS:
        run([adb,"shell","am","start","-a","android.intent.action.VIEW","-d",u]); info(f"offen: {u}")

    print("\n"+"="*60); print("  FERTIG - in der Brille:"); print("="*60)
    print("  1. Telegram -> einloggen -> /start an deinen Bot -> Mikro = Voice->Notion")
    print("  2. Browser: 5 Tabs offen -> einloggen -> Lesezeichen setzen")
    print("  3. Multi-Monitor: PICO Connect am Rechner starten")
    input("\n  [Enter] zum Schliessen ")

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n  Abbruch.")
