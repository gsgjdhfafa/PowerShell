#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO 1-KLICK  -  alles in einem Durchlauf
# ============================================================
#  Ein Doppelklick macht die ganze Kette:
#    1. Ordner + ADB sicherstellen (ADB via winget, falls noetig)
#    2. PICO verbinden (USB; oder IP eingeben fuer WLAN)
#    3. Kluge Apps installieren: Telegram, Brave, VLC, Wolvic
#    4. Login-/Dashboard-Seiten auf der Brille oeffnen
#    5. Klartext-Anleitung, was in der Brille zu tun ist
#
#  Installiert nur. Loescht nichts. Aendert keine VR-Aufloesung.
# ============================================================

import os, sys, shutil, subprocess, time, json, re, urllib.request
from pathlib import Path

BASE   = Path.home() / "PicoSetup"
APKDIR = BASE / "02_APPS" / "APPS_TO_TEST"
LOGS   = BASE / "99_REPORTS_LOGS"
for d in (APKDIR, LOGS): d.mkdir(parents=True, exist_ok=True)

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")

CURATED = [
    {"name":"Telegram","pkg":"org.telegram.messenger","why":"Voice-Diktat -> Bot -> Notion",
     "type":"direct","url":"https://telegram.org/dl/android/apk"},
    {"name":"Brave","pkg":"com.brave.browser","why":"Dashboards Notion/Gmail/Kalender/Tasks",
     "type":"github","repo":"brave/brave-browser","match":"arm64|universal"},
    {"name":"VLC","pkg":"org.videolan.vlc","why":"Medien / Fokus-Kino",
     "type":"direct","url":"https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk"},
    {"name":"Wolvic","pkg":"com.igalia.wolvic","why":"XR-Browser (optional)",
     "type":"github","repo":"Igalia/wolvic","match":"arm64|noapi"},
]
BOOKMARKS = [
    ("Notion","https://www.notion.so/login"),
    ("Gmail","https://mail.google.com"),
    ("Google Kalender","https://calendar.google.com"),
    ("Google Tasks","https://tasks.google.com"),
    ("Telegram Web","https://web.telegram.org"),
]

def run(cmd, timeout=60):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

def find_adb():
    p = shutil.which("adb")
    if p: return p
    exe = "adb.exe" if os.name=="nt" else "adb"
    for c in [BASE/"01_TOOLS"/"adb"/exe,
              Path(os.environ.get("LOCALAPPDATA",""))/"Microsoft"/"WinGet"/"Links"/exe]:
        if c.exists(): return str(c)
    return None

def ensure_adb():
    adb = find_adb()
    if adb: return adb
    if os.name == "nt":
        warn("ADB fehlt - installiere Platform-Tools (winget) ...")
        run(["winget","install","--id","Google.PlatformTools","-e","--silent",
             "--accept-package-agreements","--accept-source-agreements"], timeout=300)
        os.environ["Path"] = (os.environ.get("Path","") + ";" +
            str(Path(os.environ.get("LOCALAPPDATA",""))/"Microsoft"/"WinGet"/"Links"))
        adb = find_adb()
    return adb

def device_ok(adb):
    _, out = run([adb,"devices"])
    return any("\t" in l and l.strip().endswith("device") for l in out.splitlines())

def connect(adb):
    run([adb,"start-server"])
    if device_ok(adb): return True
    print("\n  Keine PICO per USB gefunden.")
    print("  A) USB-Kabel anstecken + in der Brille 'USB-Debugging zulassen', dann Enter")
    print("  B) Oder WLAN: IP der Pico eingeben (Einstellungen->WLAN)")
    ip = input("  Pico-IP fuer WLAN (leer = ich stecke USB an): ").strip()
    if ip:
        run([adb,"connect",f"{ip}:5555"]); time.sleep(1)
    else:
        input("  [Enter] wenn USB steckt ...")
    return device_ok(adb)

def is_installed(adb,pkg):
    _, out = run([adb,"shell","pm","list","packages",pkg]); return f"package:{pkg}" in out

def gh_url(repo,match):
    try:
        req=urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/latest",
                                   headers={"User-Agent":"PICO"})
        d=json.loads(urllib.request.urlopen(req,timeout=25).read().decode())
        apks=[a for a in d.get("assets",[]) if a["name"].endswith(".apk")]
        h=next((a for a in apks if re.search(match,a["name"])),None) or (apks[0] if apks else None)
        return h["browser_download_url"] if h else None
    except Exception: return None

def install(adb,app):
    if is_installed(adb,app["pkg"]): ok(f"{app['name']}: schon da"); return True
    url = app["url"] if app["type"]=="direct" else gh_url(app["repo"],app["match"])
    if not url: bad(f"{app['name']}: keine URL"); return False
    apk = APKDIR / f"{app['name']}.apk"
    try:
        info(f"Lade {app['name']} ...")
        req=urllib.request.Request(url,headers={"User-Agent":"PICO"})
        with urllib.request.urlopen(req,timeout=180) as r, open(apk,"wb") as f: shutil.copyfileobj(r,f)
    except Exception as e: bad(f"{app['name']}: Download-Fehler ({e})"); return False
    _, out = run([adb,"install","-r",str(apk)],timeout=240)
    if "Success" in out: ok(f"{app['name']}: installiert ({app['why']})"); return True
    bad(f"{app['name']}: {out.strip()[:150]}"); return False

def main():
    print("="*60); print("  PICO 1-KLICK  -  verbinden + kluge Apps + Zugaenge"); print("="*60)
    adb = ensure_adb()
    if not adb:
        bad("ADB konnte nicht bereitgestellt werden."); input("\n  [Enter] ..."); return
    ok(f"ADB: {adb}")
    if not connect(adb):
        bad("Keine PICO verbunden. Nochmal starten, wenn USB/WLAN steht."); input("\n  [Enter] ..."); return
    _, model = run([adb,"shell","getprop","ro.product.model"]); ok(f"Verbunden: {model.strip()}")

    print("\n--- Apps installieren ---")
    res = {a["name"]: install(adb,a) for a in CURATED}

    print("\n--- Login-/Dashboard-Seiten auf der Brille oeffnen ---")
    for name,url in BOOKMARKS:
        run([adb,"shell","am","start","-a","android.intent.action.VIEW","-d",url]); info(f"offen: {name}")

    print("\n" + "="*60); print("  FERTIG - jetzt in der Brille:"); print("="*60)
    print("  1. Telegram -> einloggen -> /start an deinen Bot -> Mikro = Voice->Notion")
    print("  2. Browser: 5 Tabs offen -> einloggen -> als Lesezeichen sichern")
    print("  3. Multi-Monitor: PICO Connect am PC starten")
    print("\n  Ergebnis:", ", ".join(f"{k}={'OK' if v else 'X'}" for k,v in res.items()))
    input("\n  [Enter] zum Schliessen ...")

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n  Abbruch.")
