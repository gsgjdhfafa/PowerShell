#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO CONTROL CENTER v2  -  Modifikationsbasis (sicher & umkehrbar)
# ============================================================
#  Doppelklick oder:  python PICO_CONTROL_CENTER.py
#  Zahl tippen + Enter.
#
#  SICHERHEITS-PRINZIP:
#   - Nichts wird geloescht. Mods = EINFRIEREN (disable-user), umkehrbar.
#   - VR-Aufloesung wird NICHT veraendert (Bildschirm-Setups PC-seitig).
#   - Kritische System-/Pico-Apps sind gesperrt (kein Bricken moeglich).
#   - Vor jeder Aenderung: Report. Auswahl immer manuell + Bestaetigung.
# ============================================================

import os, sys, shutil, subprocess, datetime, re
from pathlib import Path

def base_dir():
    here = Path(__file__).resolve().parent
    if here.name.lower() == "picosetup":
        return here
    return Path.home() / "PicoSetup"

BASE    = base_dir()
TOOLS   = BASE / "01_TOOLS"
TOTEST  = BASE / "02_APPS" / "APPS_TO_TEST"
APPROV  = BASE / "02_APPS" / "APPS_APPROVED"
REPORTS = BASE / "02_APPS" / "APP_REPORTS"
TOPICO  = BASE / "03_MEDIA" / "TO_PICO"
FROMPICO= BASE / "03_MEDIA" / "FROM_PICO"
DLPC    = BASE / "03_MEDIA" / "DOWNLOADS_PC"
BKAPK   = BASE / "04_BACKUP_CLONE" / "FROM_PICO"
LOGS    = BASE / "99_REPORTS_LOGS"
FROZEN  = LOGS / "eingefroren.txt"

# Diese Muster werden NIE eingefroren (sonst Brick-Gefahr):
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

def find_tool(name, sub):
    exe = f"{name}.exe" if os.name == "nt" else name
    p = shutil.which(name)
    if p: return p
    local = TOOLS / sub / exe
    if local.exists(): return str(local)
    if os.name == "nt":
        wg = Path(os.environ.get("LOCALAPPDATA","")) / "Microsoft" / "WinGet" / "Links" / exe
        if wg.exists(): return str(wg)
    return None

def find_adb():    return find_tool("adb","adb")
def find_scrcpy(): return find_tool("scrcpy","scrcpy")
def find_ytdlp():  return find_tool("yt-dlp","yt-dlp")

def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return 1, str(e)

def device_ok(adb):
    if not adb: return False
    _, out = run([adb,"devices"])
    return any("\t" in l and l.strip().endswith("device") for l in out.splitlines())

def need_device(adb):
    if not adb: bad("ADB fehlt. Erst START_PICO_CONTROL_CENTER.py ausfuehren."); return False
    if not device_ok(adb): bad("Keine PICO verbunden (USB oder WLAN-ADB)."); return False
    return True

def user_apps(adb):
    _, out = run([adb,"shell","pm","list","packages","-3"])
    return sorted(l.replace("package:","").strip() for l in out.splitlines() if l.strip())

def pick_from(items, prompt="   Nummer (leer = abbrechen): "):
    for i, x in enumerate(items, 1): print(f"   {i:>3}) {x}")
    sel = input(prompt).strip()
    if sel.isdigit() and 1 <= int(sel) <= len(items):
        return items[int(sel)-1]
    return None

# ============================================================
# VERBINDUNG
# ============================================================
def act_status(adb):
    print("\n--- Status ---")
    if not adb: bad("ADB fehlt."); return
    _, out = run([adb,"devices","-l"]); print(out.strip())
    if device_ok(adb):
        _, model = run([adb,"shell","getprop","ro.product.model"])
        _, ver   = run([adb,"shell","getprop","ro.build.version.release"])
        _, bat   = run([adb,"shell","dumpsys","battery"])
        lvl = next((l.split("level:")[1].strip() for l in bat.splitlines() if "level:" in l), "?")
        ok(f"{model.strip()}  Android {ver.strip()}  Akku {lvl}%")

def act_wifi_adb(adb):
    print("\n--- WLAN-ADB (ohne USB weiterarbeiten) ---")
    if not adb: bad("ADB fehlt."); return
    if not device_ok(adb):
        bad("Bitte EINMAL per USB verbinden, um WLAN-ADB zu aktivieren."); return
    ip = None
    _, r = run([adb,"shell","ip","-f","inet","addr","show","wlan0"])
    m = re.search(r"inet (\d+\.\d+\.\d+\.\d+)", r)
    if m: ip = m.group(1)
    if not ip:
        _, r2 = run([adb,"shell","ip","route"])
        m2 = re.search(r"src (\d+\.\d+\.\d+\.\d+)", r2)
        if m2: ip = m2.group(1)
    if not ip:
        warn("IP nicht gefunden. In der Brille: Einstellungen -> WLAN -> IP ablesen.")
        ip = input("   IP der Pico eingeben (leer = abbrechen): ").strip()
        if not ip: return
    info(f"Pico-IP: {ip}")
    run([adb,"tcpip","5555"])
    code, out = run([adb,"connect",f"{ip}:5555"])
    if "connected" in out.lower():
        ok(f"WLAN-ADB aktiv: {ip}:5555")
        info("Du kannst das USB-Kabel jetzt abziehen. (Gilt bis Pico-Neustart.)")
    else:
        bad(f"Verbindung fehlgeschlagen: {out.strip()}")

# ============================================================
# BILDSCHIRM (PC-seitig)
# ============================================================
def act_scrcpy(adb, mode):
    scr = find_scrcpy()
    if not scr: bad("scrcpy fehlt. Portable nach 01_TOOLS\\scrcpy\\ entpacken (kostenlos)."); return
    if not need_device(adb): return
    args = [scr]
    if mode == "one_eye":
        args += ["--crop","2160:2160:0:0","--window-title","PICO - ein Auge"]; info("Nur ein Auge (empfohlen).")
    elif mode == "light":
        args += ["--max-size","1280","--video-bit-rate","4M","--window-title","PICO - sparsam"]; info("Sparsam.")
    elif mode == "record":
        FROMPICO.mkdir(parents=True, exist_ok=True)
        o = FROMPICO / f"aufnahme_{stamp()}.mp4"; args += ["--crop","2160:2160:0:0","--record",str(o)]; info(f"Aufnahme -> {o}")
    else:
        args += ["--window-title","PICO - voll"]; info("Beide Augen.")
    try: subprocess.Popen(args); ok("scrcpy gestartet.")
    except Exception as e: bad(str(e))

def act_pico_connect():
    cands = [Path(os.environ.get("LOCALAPPDATA","")) / "Programs" / "PICO Connect" / "PICO Connect.exe",
             Path(os.environ.get("ProgramFiles","")) / "PICO Connect" / "PICO Connect.exe"]
    exe = next((str(p) for p in cands if p.exists()), None)
    if exe:
        try: subprocess.Popen([exe]); ok("PICO Connect gestartet.")
        except Exception as e: bad(str(e))
    else:
        warn("PICO Connect nicht gefunden - kostenlos: picoxr.com/global/software/pico-connect")

# ============================================================
# APPS + INVENTAR + BACKUP
# ============================================================
def act_list_apps(adb):
    if not need_device(adb): return
    pkgs = user_apps(adb)
    print(f"\n--- {len(pkgs)} von dir installierte Apps ---")
    for p in pkgs: print("   ", p)
    REPORTS.mkdir(parents=True, exist_ok=True)
    rep = REPORTS / f"apps_{stamp()}.txt"; rep.write_text("\n".join(pkgs), encoding="utf-8")
    ok(f"Report: {rep}")

def act_inventory(adb):
    if not need_device(adb): return
    LOGS.mkdir(parents=True, exist_ok=True)
    rep = LOGS / f"inventar_{stamp()}.txt"
    lines = []
    def sec(t): lines.append(""); lines.append("="*50); lines.append(t); lines.append("="*50)
    _, model = run([adb,"shell","getprop","ro.product.model"])
    _, dev   = run([adb,"shell","getprop","ro.product.device"])
    _, ver   = run([adb,"shell","getprop","ro.build.version.release"])
    _, fw    = run([adb,"shell","getprop","ro.build.display.id"])
    sec("GERAET")
    lines += [f"Modell: {model.strip()}", f"Device: {dev.strip()}", f"Android: {ver.strip()}", f"Firmware: {fw.strip()}"]
    _, df = run([adb,"shell","df","-h","/sdcard"]); sec("SPEICHER (/sdcard)"); lines.append(df.strip())
    _, u = run([adb,"shell","pm","list","packages","-3"])
    ua = sorted(l.replace("package:","").strip() for l in u.splitlines() if l.strip())
    sec(f"USER-APPS ({len(ua)})  <- hier lohnt Aufraeumen"); lines += ua
    _, s = run([adb,"shell","pm","list","packages","-s"])
    sa = sorted(l.replace("package:","").strip() for l in s.splitlines() if l.strip())
    sec(f"SYSTEM-APPS ({len(sa)})  <- Vorsicht, meist noetig"); lines += sa
    rep.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n--- Inventar: {len(ua)} User-Apps, {len(sa)} System-Apps ---")
    ok(f"Voll-Report gespeichert: {rep}")
    info("Diesen Report kannst du mir in den Chat einfuegen - dann empfehle ich sicheres Aufraeumen.")

def act_space_setup(adb):
    print("\n--- Umgebungsaufzeichnung (Space Setup / Raum scannen) ---")
    if not need_device(adb): return
    info("Das eigentliche Scannen (Wand-/Bodenerkennung) geht NUR im Headset -")
    info("per Kamera-Tracking, nicht per ADB automatisierbar.")
    run([adb, "shell", "am", "start", "-a", "android.settings.SETTINGS"])
    ok("Settings in der Brille geoeffnet.")
    print("""
    Naechste Schritte IM HEADSET:
      1. Einstellungen -> Allgemein -> "Physischer Raum" / "Play Area" /
         "Space Setup" (Bezeichnung variiert je nach PICO-OS-Version).
      2. Neuen Raum einrichten -> mit dem Controller die Boden-/Wandgrenze
         abfahren, bis der Scan abgeschlossen ist.
      3. Bildschirme/Fenster an Waende pinnen: in MR-faehigen Apps
         (z.B. PICO Connect fuer virtuelle Monitore) nach dem Scan verfuegbar.
      4. Objekte "funktionalisieren" (z.B. Papierkorb als Trigger/Anker):
         im Menu "Mixed Reality" / "Anker" bzw. "Spatial Anchors" - variiert
         je nach Firmware, aktuell keine ADB-Automatisierung moeglich.
    """)

def act_audit(adb):
    print("\n--- AUDIT: was laeuft, was muss weg, was muss drauf? ---")
    if not need_device(adb): return
    # -e = nur aktive (enabled), -d = nur eingefrorene (disabled).
    # "pm list packages -3" ohne -e/-d zeigt AUCH eingefrorene Apps -
    # die verschwinden durch Einfrieren nicht aus der Liste, nur aus dem Betrieb.
    _, u_all = run([adb,"shell","pm","list","packages","-3"])
    user_pkgs_all = sorted(l.replace("package:","").strip() for l in u_all.splitlines() if l.strip())
    _, u = run([adb,"shell","pm","list","packages","-3","-e"])
    user_pkgs = sorted(l.replace("package:","").strip() for l in u.splitlines() if l.strip())
    _, u_d = run([adb,"shell","pm","list","packages","-3","-d"])
    user_pkgs_frozen = sorted(l.replace("package:","").strip() for l in u_d.splitlines() if l.strip())
    _, s = run([adb,"shell","pm","list","packages","-s"])
    sys_pkgs = sorted(l.replace("package:","").strip() for l in s.splitlines() if l.strip())
    all_pkgs = set(user_pkgs_all) | set(sys_pkgs)

    missing_targets = [p for p in TARGETS if p not in all_pkgs]
    present_targets  = [p for p in TARGETS if p in all_pkgs]
    candidates = [p for p in user_pkgs if p not in TARGETS and not is_critical(p)]
    crit       = sorted(p for p in all_pkgs if is_critical(p))
    sys_other  = sorted(p for p in sys_pkgs if not is_critical(p))

    lines = [f"AUDIT {stamp()}"]
    def sec(t): lines.append(""); lines.append("="*60); lines.append(t); lines.append("="*60)

    print(f"\n[1] ZIEL-APPS - {len(present_targets)}/{len(TARGETS)} vorhanden")
    sec(f"ZIEL-APPS - {len(present_targets)}/{len(TARGETS)} vorhanden")
    for p, name in TARGETS.items():
        line = f"  [{'OK' if p in all_pkgs else 'X '}] {name:32s} ({p})"
        print(line); lines.append(line)

    print(f"\n[2] KANDIDATEN ZUM EINFRIEREN - {len(candidates)} App(s)")
    info("Von dir installiert, nicht Teil unseres Setups. Ueber Punkt 12 einfrierbar.")
    sec(f"KANDIDATEN ZUM EINFRIEREN ({len(candidates)})")
    for p in candidates: print(f"    - {p}"); lines.append(f"  - {p}")
    if not candidates: print("    (keine)")

    print(f"\n[3] BEREITS EINGEFROREN - {len(user_pkgs_frozen)} App(s)")
    sec(f"BEREITS EINGEFROREN ({len(user_pkgs_frozen)})")
    for p in user_pkgs_frozen: print(f"    - {p}"); lines.append(f"  - {p}")
    if not user_pkgs_frozen: print("    (keine)")

    print(f"\n[4] GESPERRT/KRITISCH - {len(crit)} System-Pakete (bleiben)")
    sec(f"GESPERRT/KRITISCH ({len(crit)})"); lines += [f"  - {p}" for p in crit]
    sec(f"SONSTIGE SYSTEM-APPS ({len(sys_other)})"); lines += [f"  - {p}" for p in sys_other]

    LOGS.mkdir(parents=True, exist_ok=True)
    rep = LOGS / f"audit_{stamp()}.txt"; rep.write_text("\n".join(lines), encoding="utf-8")
    ok(f"Report: {rep}")
    if missing_targets: warn(f"Fehlt: {', '.join(TARGETS[p] for p in missing_targets)} -> PICO_WINDOWS.ps1 erneut.")
    if candidates: warn(f"{len(candidates)} Kandidat(en) zum Einfrieren -> Punkt 12.")
    if not missing_targets and not candidates: ok("Sauber: alles da, nichts Fremdes.")

def act_install_apk(adb):
    if not need_device(adb): return
    TOTEST.mkdir(parents=True, exist_ok=True)
    apks = sorted(TOTEST.glob("*.apk"))
    if not apks: warn(f"Keine APKs in {TOTEST}"); return
    print("\n--- APKs in APPS_TO_TEST ---")
    apk = pick_from([a.name for a in apks])
    if not apk: info("Abgebrochen."); return
    path = TOTEST / apk
    info(f"Installiere {apk} ...")
    _, out = run([adb,"install","-r",str(path)], timeout=180)
    if "Success" in out:
        ok("Installiert.")
        if input("   Nach APPS_APPROVED verschieben? [j/N] ").strip().lower() in ("j","ja","y"):
            APPROV.mkdir(parents=True, exist_ok=True); shutil.move(str(path), str(APPROV/apk)); ok("Verschoben.")
    else:
        bad(out.strip()[:200])

def act_backup_apk(adb):
    if not need_device(adb): return
    pkgs = user_apps(adb)
    if not pkgs: warn("Keine User-Apps."); return
    print("\n--- APK sichern (welche App?) ---")
    pkg = pick_from(pkgs)
    if not pkg: info("Abgebrochen."); return
    _, path = run([adb,"shell","pm","path",pkg])
    apkpaths = [l.replace("package:","").strip() for l in path.splitlines() if l.startswith("package:")]
    if not apkpaths: bad("Pfad nicht gefunden."); return
    BKAPK.mkdir(parents=True, exist_ok=True)
    dest = BKAPK / f"{pkg}.apk"
    code, out = run([adb,"pull",apkpaths[0],str(dest)], timeout=300)
    (ok if code==0 else bad)(f"Gesichert: {dest}" if code==0 else out.strip()[:150])

# ============================================================
# MODIFIKATION (umkehrbar)
# ============================================================
def _log_frozen(pkg, action):
    LOGS.mkdir(parents=True, exist_ok=True)
    with open(FROZEN, "a", encoding="utf-8") as f:
        f.write(f"{stamp()}\t{action}\t{pkg}\n")

def act_freeze(adb):
    print("\n--- App EINFRIEREN (umkehrbar, nicht geloescht) ---")
    if not need_device(adb): return
    pkgs = user_apps(adb)
    if not pkgs: warn("Keine User-Apps zum Einfrieren."); return
    info("Nur von dir installierte Apps. System/Pico-Apps sind gesperrt.")
    pkg = pick_from(pkgs)
    if not pkg: info("Abgebrochen."); return
    if is_critical(pkg):
        bad(f"GESPERRT: {pkg} sieht systemkritisch aus - wird nicht angefasst."); return
    print(f"\n   App:  {pkg}")
    print("   'Einfrieren' blendet die App aus (laeuft nicht mehr), loescht sie NICHT.")
    print("   Jederzeit ueber Menuepunkt 'App auftauen' zurueck.")
    if input("   Wirklich einfrieren? Tippe JA: ").strip() != "JA":
        info("Abgebrochen."); return
    code, out = run([adb,"shell","pm","disable-user","--user","0",pkg])
    if "new state" in out.lower() or "disabled" in out.lower() or code==0:
        ok(f"Eingefroren: {pkg}"); _log_frozen(pkg,"FREEZE")
    else:
        bad(f"Fehlgeschlagen: {out.strip()[:150]}")

def act_unfreeze(adb):
    print("\n--- App AUFTAUEN (wieder aktivieren) ---")
    if not need_device(adb): return
    frozen = []
    if FROZEN.exists():
        for l in FROZEN.read_text(encoding="utf-8").splitlines():
            parts = l.split("\t")
            if len(parts)==3 and parts[1]=="FREEZE" and parts[2] not in frozen:
                frozen.append(parts[2])
    if frozen:
        info("Zuvor eingefrorene Apps:")
        pkg = pick_from(frozen, "   Nummer (oder leer, um Paket selbst einzutippen): ")
    else:
        pkg = None
    if not pkg:
        pkg = input("   Paketname zum Auftauen: ").strip()
    if not pkg: info("Abgebrochen."); return
    code, out = run([adb,"shell","pm","enable",pkg])
    if "enabled" in out.lower() or code==0:
        ok(f"Aufgetaut: {pkg}"); _log_frozen(pkg,"UNFREEZE")
    else:
        bad(f"Fehlgeschlagen: {out.strip()[:150]}")

# ============================================================
# MEDIEN
# ============================================================
def act_push_media(adb):
    if not need_device(adb): return
    TOPICO.mkdir(parents=True, exist_ok=True)
    files = [f for f in sorted(TOPICO.iterdir()) if f.is_file()]
    if not files: warn(f"Nichts in {TOPICO} - Dateien hineinlegen."); return
    print("\n--- Dateien in TO_PICO ---")
    for i,f in enumerate(files,1): print(f"   {i}) {f.name}")
    sel = input("   Nummer (leer = ALLE): ").strip()
    targets = files if sel=="" else ([files[int(sel)-1]] if sel.isdigit() and 1<=int(sel)<=len(files) else [])
    if not targets: info("Abgebrochen."); return
    for f in targets:
        code,out = run([adb,"push",str(f),"/sdcard/Movies/"], timeout=600)
        (ok if code==0 else bad)(f"{f.name} -> /sdcard/Movies/" if code==0 else out.strip()[:120])

def act_screenshot(adb):
    if not need_device(adb): return
    FROMPICO.mkdir(parents=True, exist_ok=True)
    out = FROMPICO / f"screenshot_{stamp()}.png"
    try:
        with open(out,"wb") as fh:
            subprocess.run([adb,"exec-out","screencap","-p"], stdout=fh, timeout=30)
        (ok if out.stat().st_size>0 else bad)(f"Screenshot: {out}" if out.stat().st_size>0 else "Leer.")
    except Exception as e: bad(str(e))

def act_ytdlp(adb):
    y = find_ytdlp()
    if not y:
        if input("   yt-dlp fehlt. Jetzt nach 01_TOOLS\\yt-dlp\\ laden? [j/N] ").strip().lower() in ("j","ja","y") and os.name=="nt":
            (TOOLS/"yt-dlp").mkdir(parents=True, exist_ok=True); tgt=TOOLS/"yt-dlp"/"yt-dlp.exe"
            try:
                import urllib.request; info("Lade ...")
                urllib.request.urlretrieve("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe", tgt)
                y=str(tgt); ok("yt-dlp bereit.")
            except Exception as e: bad(str(e)); return
        else: return
    url=""
    try:
        import tkinter; r=tkinter.Tk(); r.withdraw(); url=r.clipboard_get(); r.destroy()
    except Exception:
        if os.name=="nt": _,cb=run(["powershell","-NoProfile","-Command","Get-Clipboard"]); url=cb.strip()
    url = input(f"   Video-URL [{url[:40]}]: ").strip() or url
    if not url: info("Keine URL."); return
    DLPC.mkdir(parents=True, exist_ok=True); info("Lade Video ...")
    _,out = run([y,"-f","bv*+ba/b","--merge-output-format","mp4","-o",str(DLPC/"%(title)s.%(ext)s"),url], timeout=1800)
    print(out.strip()[-300:])
    news = sorted(DLPC.glob("*.mp4"), key=lambda p:p.stat().st_mtime, reverse=True)
    if news:
        ok(f"Gespeichert: {news[0].name}")
        if adb and device_ok(adb) and input("   Auf die PICO schieben? [j/N] ").strip().lower() in ("j","ja","y"):
            c,o=run([adb,"push",str(news[0]),"/sdcard/Movies/"],timeout=600); (ok if c==0 else bad)("Auf Brille." if c==0 else o[:120])

# ============================================================
# SYSTEM
# ============================================================
def act_toolcheck():
    print("\n--- Tools ---")
    for n,f in [("ADB",find_adb()),("scrcpy",find_scrcpy()),("yt-dlp",find_ytdlp())]:
        (ok if f else warn)(f"{n}: {f if f else 'fehlt (kostenlos nachruestbar)'}")

def act_sync_shared():
    print("\n--- Kopie nach shared\\Picco ---")
    src = BASE
    raw = input("   Pfad zu 'shared' (z.B. Z:\\shared oder \\\\NAS\\shared): ").strip().strip('"')
    if not raw: info("Abgebrochen."); return
    shared = Path(raw)
    if not shared.exists():
        if input(f"   {shared} existiert nicht. Anlegen? [j/N] ").strip().lower() not in ("j","ja","y"): return
        shared.mkdir(parents=True, exist_ok=True)
    dst = shared / "Picco"; dst.mkdir(parents=True, exist_ok=True)
    n=0
    for root,_,fs in os.walk(src):
        rel=Path(root).relative_to(src); (dst/rel).mkdir(parents=True, exist_ok=True)
        for fn in fs:
            s=Path(root)/fn; d=dst/rel/fn
            try:
                if not d.exists() or s.stat().st_size!=d.stat().st_size:
                    shutil.copy2(s,d); n+=1
            except Exception: pass
    ok(f"Kopiert/aktualisiert: {n} Datei(en) -> {dst}  (nichts geloescht)")

# ============================================================
# MENUE
# ============================================================
MENU = """
============================================================
  PICO CONTROL CENTER v2  -  Modifikationsbasis
============================================================
  VERBINDUNG
   1) Status anzeigen
   2) WLAN-ADB einrichten (ohne USB weiterarbeiten)

  BILDSCHIRM (PC-seitig, sicher)
   3) Live: nur EIN Auge (empfohlen)
   4) Live: volle Ansicht
   5) Live: sparsam
   6) Aufnehmen -> FROM_PICO
   7) PICO Connect (virtuelle Monitore)

  APPS
   8) Apps auflisten + Report
   9) VOLL-INVENTAR (System+User+Speicher) -> Report
  10) APK installieren (APPS_TO_TEST)
  11) App-APK sichern -> Backup
  19) AUDIT: was laeuft / was weg / was fehlt (Ziel-Apps-Abgleich)
  20) Umgebungsaufzeichnung / Space Setup (Raum scannen, Anker)

  MODIFIKATION (umkehrbar, nichts wird geloescht)
  12) App EINFRIEREN (disable-user)
  13) App AUFTAUEN (enable)

  MEDIEN
  14) Datei(en) auf die PICO kopieren
  15) Screenshot holen
  16) Video-URL laden (yt-dlp)

  SYSTEM
  17) Tools pruefen
  18) Kopie nach shared\\Picco
   0) Beenden
------------------------------------------------------------"""

def main():
    adb = find_adb()
    while True:
        print(MENU)
        if adb and device_ok(adb): print("  Status: PICO verbunden.")
        elif adb:                  print("  Status: ADB da, keine PICO.")
        else:                      print("  Status: ADB fehlt.")
        c = input("  Auswahl: ").strip()
        if   c=="0": print("  Tschuess."); break
        elif c=="1": act_status(adb)
        elif c=="2": act_wifi_adb(adb)
        elif c=="3": act_scrcpy(adb,"one_eye")
        elif c=="4": act_scrcpy(adb,"full")
        elif c=="5": act_scrcpy(adb,"light")
        elif c=="6": act_scrcpy(adb,"record")
        elif c=="7": act_pico_connect()
        elif c=="8": act_list_apps(adb)
        elif c=="9": act_inventory(adb)
        elif c=="10": act_install_apk(adb)
        elif c=="11": act_backup_apk(adb)
        elif c=="19": act_audit(adb)
        elif c=="20": act_space_setup(adb)
        elif c=="12": act_freeze(adb)
        elif c=="13": act_unfreeze(adb)
        elif c=="14": act_push_media(adb)
        elif c=="15": act_screenshot(adb)
        elif c=="16": act_ytdlp(adb)
        elif c=="17": act_toolcheck()
        elif c=="18": act_sync_shared()
        else: warn("Unbekannte Auswahl.")
        adb = find_adb()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n  Abbruch.")
