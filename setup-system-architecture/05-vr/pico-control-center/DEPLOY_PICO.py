#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  DEPLOY_PICO  -  Kluge Einsatzstellen in einem Klick
# ============================================================
#  Bringt genau die Apps + Zugaenge auf die PICO 4 Ultra, die
#  laut eigener Use-Case-Analyse (05-vr/USE-CASES.md) validiert sind:
#
#   1. Telegram  -> Voice-Diktat -> dein Bot -> Notion  (#1 Use-Case)
#   2. Browser   -> Dashboards Notion/Gmail/Calendar/Tasks (glanceable)
#   3. VLC       -> lokale Medien / Fokus-Kino-Bubble
#   4. Wolvic    -> XR-Browser fuer immersives Web (optional)
#
#  Danach werden die Login-/Bookmark-Seiten direkt auf der Brille
#  geoeffnet - du musst dich nur noch einloggen.
#
#  SICHER: installiert nur, deinstalliert/loescht nichts.
#  Start:  python DEPLOY_PICO.py            (USB oder WLAN-ADB)
#          python DEPLOY_PICO.py --wifi 192.168.x.y   (per Netzwerk)
# ============================================================

import os, sys, shutil, subprocess, datetime, urllib.request, json
from pathlib import Path

def base_dir():
    here = Path(__file__).resolve().parent
    if here.name.lower() == "picosetup": return here
    return Path.home() / "PicoSetup"

BASE  = base_dir()
TOOLS = BASE / "01_TOOLS"
APKDIR= BASE / "02_APPS" / "APPS_TO_TEST"
LOGS  = BASE / "99_REPORTS_LOGS"

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")
def stamp(): return datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

# --- Kuratierte Apps: an die validierten Use-Cases gekoppelt ---
CURATED = [
    {"name":"Telegram", "pkg":"org.telegram.messenger", "why":"Voice-Diktat -> dein Bot -> Notion (validierter #1 Use-Case)",
     "type":"direct", "url":"https://telegram.org/dl/android/apk"},
    {"name":"Brave",    "pkg":"com.brave.browser", "why":"Dashboards: Notion/Gmail/Calendar/Tasks glanceable",
     "type":"github", "repo":"brave/brave-browser", "match":"arm64|universal"},
    {"name":"VLC",      "pkg":"org.videolan.vlc", "why":"Lokale Medien / Fokus-Kino-Bubble",
     "type":"direct", "url":"https://get.videolan.org/vlc-android/last/VLC-Android-arm64-v8a.apk"},
    {"name":"Wolvic",   "pkg":"com.igalia.wolvic", "why":"XR-Browser fuer immersives Web (optional)",
     "type":"github", "repo":"Igalia/wolvic", "match":"arm64|noapi"},
]

# --- Bookmarks/Logins die auf der Brille geoeffnet werden ---
BOOKMARKS = [
    ("Notion",        "https://www.notion.so/login"),
    ("Gmail",         "https://mail.google.com"),
    ("Google Kalender","https://calendar.google.com"),
    ("Google Tasks",  "https://tasks.google.com"),
    ("Telegram Web",  "https://web.telegram.org"),
]

def find_adb():
    exe = "adb.exe" if os.name == "nt" else "adb"
    p = shutil.which("adb")
    if p: return p
    local = TOOLS / "adb" / exe
    if local.exists(): return str(local)
    if os.name == "nt":
        wg = Path(os.environ.get("LOCALAPPDATA","")) / "Microsoft" / "WinGet" / "Links" / "adb.exe"
        if wg.exists(): return str(wg)
    return None

def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

def device_ok(adb):
    _, out = run([adb,"devices"])
    return any("\t" in l and l.strip().endswith("device") for l in out.splitlines())

def wifi_connect(adb, ip):
    info(f"Verbinde per WLAN-ADB mit {ip}:5555 ...")
    run([adb,"connect",f"{ip}:5555"])
    return device_ok(adb)

def is_installed(adb, pkg):
    _, out = run([adb,"shell","pm","list","packages",pkg])
    return f"package:{pkg}" in out

def resolve_github(repo, match):
    try:
        req = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/latest",
                                     headers={"User-Agent":"PICO-Deploy"})
        data = json.loads(urllib.request.urlopen(req, timeout=25).read().decode())
        import re
        apks = [a for a in data.get("assets",[]) if a["name"].endswith(".apk")]
        hit = next((a for a in apks if re.search(match, a["name"])), None) or (apks[0] if apks else None)
        return hit["browser_download_url"] if hit else None
    except Exception as e:
        warn(f"GitHub-Release nicht erreichbar ({repo}): {e}"); return None

def install_app(adb, app):
    if is_installed(adb, app["pkg"]):
        ok(f"{app['name']}: schon installiert"); return True
    url = app["url"] if app["type"]=="direct" else resolve_github(app["repo"], app["match"])
    if not url: bad(f"{app['name']}: keine Download-URL"); return False
    APKDIR.mkdir(parents=True, exist_ok=True)
    apk = APKDIR / f"{app['name']}.apk"
    try:
        info(f"Lade {app['name']} ...")
        req = urllib.request.Request(url, headers={"User-Agent":"PICO-Deploy"})
        with urllib.request.urlopen(req, timeout=180) as r, open(apk,"wb") as f:
            shutil.copyfileobj(r, f)
    except Exception as e:
        bad(f"{app['name']}: Download-Fehler ({e})"); return False
    _, out = run([adb,"install","-r",str(apk)], timeout=240)
    if "Success" in out: ok(f"{app['name']}: installiert  ({app['why']})"); return True
    bad(f"{app['name']}: {out.strip()[:160]}"); return False

def open_bookmarks(adb):
    for name, url in BOOKMARKS:
        run([adb,"shell","am","start","-a","android.intent.action.VIEW","-d",url])
        info(f"geoeffnet: {name}")

def main():
    print("="*60); print("  DEPLOY PICO  -  kluge Einsatzstellen"); print("="*60)
    adb = find_adb()
    if not adb:
        bad("ADB fehlt. Erst START_PICO_CONTROL_CENTER.py / winget install Google.PlatformTools.")
        input("\n  [Enter] ..."); return
    run([adb,"start-server"])

    # optional WLAN
    if "--wifi" in sys.argv:
        try: ip = sys.argv[sys.argv.index("--wifi")+1]
        except IndexError: ip = ""
        if ip and not wifi_connect(adb, ip):
            bad("WLAN-ADB fehlgeschlagen. Einmal per USB verbinden + Menue 2 nutzen.")
    if not device_ok(adb):
        bad("Keine PICO verbunden.")
        info("USB anstecken + USB-Debugging bestaetigen, ODER --wifi <IP> nutzen.")
        input("\n  [Enter] ..."); return

    _, model = run([adb,"shell","getprop","ro.product.model"])
    ok(f"Verbunden: {model.strip()}")

    print("\n--- 1) Kuratierte Apps installieren ---")
    results = {a["name"]: install_app(adb, a) for a in CURATED}

    print("\n--- 2) Login-/Dashboard-Seiten auf der Brille oeffnen ---")
    open_bookmarks(adb)

    # Report
    LOGS.mkdir(parents=True, exist_ok=True)
    rep = LOGS / f"deploy_{stamp()}.txt"
    lines = [f"DEPLOY {stamp()}", f"Geraet: {model.strip()}", "", "Apps:"]
    lines += [f"  [{'OK' if v else 'FEHLER'}] {k}" for k,v in results.items()]
    lines += ["", "Geoeffnete Seiten:"] + [f"  {n}: {u}" for n,u in BOOKMARKS]
    rep.write_text("\n".join(lines), encoding="utf-8")

    print("\n" + "="*60); print("  FERTIG - jetzt in der Brille:"); print("="*60)
    print("  1. Telegram oeffnen -> einloggen -> deinem Bot /start schicken")
    print("     -> Mikro-Button = Voice-Diktat -> landet in Notion")
    print("  2. Browser: die 5 Tabs sind offen -> ueberall einloggen, als Lesezeichen sichern")
    print("  3. Multi-Monitor: PICO Connect am PC (Menue 7) fuer bis zu 3 Desktops")
    ok(f"Report: {rep}")
    input("\n  [Enter] zum Schliessen ...")

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n  Abbruch.")
