#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
#  PICO Control Center - Kopie nach  <shared>\Picco
# ============================================================
#  Legt unter dem Netzwerkordner "shared" einen Unterordner
#  "Picco" an und kopiert das PicoSetup-Verzeichnis hinein.
#
#  SICHER: kopiert/aktualisiert nur. Loescht am Ziel NICHTS.
#  Beliebig oft ausfuehrbar (frischt die Kopie auf).
#
#  Start: Doppelklick, oder:
#     python SYNC_TO_SHARED.py
#     python SYNC_TO_SHARED.py "Z:\shared"
# ============================================================

import os, sys, shutil, datetime
from pathlib import Path

SUBFOLDER = "Picco"

def ok(m):   print(f"  [OK]  {m}")
def warn(m): print(f"  [!]   {m}")
def bad(m):  print(f"  [X]   {m}")
def info(m): print(f"        {m}")

def find_source():
    for c in [Path.home() / "PicoSetup", Path(r"C:\Users\Gerrit\PicoSetup")]:
        if c.exists(): return c
    return None

def find_shared():
    if len(sys.argv) > 1:
        p = Path(sys.argv[1])
        if p.exists(): return p
        warn(f"Angegebener Pfad existiert nicht: {p}")
    hits = []
    if os.name == "nt":
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            root = Path(f"{letter}:\\")
            try:
                if not root.exists(): continue
                for name in ("shared","Shared","SHARED"):
                    cand = root / name
                    if cand.is_dir(): hits.append(cand)
            except Exception: continue
    for base in (Path.home(), Path(os.environ.get("USERPROFILE", str(Path.home())))):
        for name in ("shared","Shared"):
            cand = base / name
            if cand.is_dir(): hits.append(cand)
    uniq = []
    for h in hits:
        if h not in uniq: uniq.append(h)
    return uniq

def pick_target():
    found = find_shared()
    if isinstance(found, Path): return found
    if len(found) == 1: ok(f"Netzwerkordner gefunden: {found[0]}"); return found[0]
    if len(found) > 1:
        print("\n  Mehrere 'shared'-Ordner gefunden:")
        for i, h in enumerate(found, 1): print(f"   {i}) {h}")
        sel = input("   Nummer waehlen (leer = abbrechen): ").strip()
        if sel.isdigit() and 1 <= int(sel) <= len(found): return found[int(sel)-1]
        return None
    warn("Keinen 'shared'-Ordner automatisch gefunden.")
    info("Beispiele:  Z:\\shared    oder    \\\\NAS\\shared")
    raw = input("   Vollen Pfad zu 'shared' einfuegen (leer = abbrechen): ").strip().strip('"')
    if not raw: return None
    p = Path(raw)
    if not p.exists():
        if input(f"   {p} existiert nicht. Anlegen? [j/N] ").strip().lower() in ("j","ja","y"):
            try: p.mkdir(parents=True, exist_ok=True)
            except Exception as e: bad(f"Konnte nicht anlegen: {e}"); return None
        else: return None
    return p

def human(n):
    for u in ("B","KB","MB","GB"):
        if n < 1024: return f"{n:.0f} {u}"
        n /= 1024
    return f"{n:.1f} TB"

def copy_tree(src, dst, excludes):
    files, total = 0, 0
    for root, dirs, fnames in os.walk(src):
        rel = Path(root).relative_to(src)
        if excludes and rel.parts and rel.parts[0] in excludes:
            dirs[:] = []; continue
        (dst / rel).mkdir(parents=True, exist_ok=True)
        for fn in fnames:
            s = Path(root) / fn; d = dst / rel / fn
            try:
                if (not d.exists()) or (s.stat().st_mtime > d.stat().st_mtime + 1) or (s.stat().st_size != d.stat().st_size):
                    shutil.copy2(s, d); files += 1; total += s.stat().st_size
            except Exception as e:
                warn(f"Uebersprungen {s.name}: {e}")
    return files, total

def main():
    print("-"*60); print("  PICO -> shared\\Picco   (sichere Kopie)"); print("-"*60)
    src = find_source()
    if not src: bad("Quelle nicht gefunden (C:\\Users\\Gerrit\\PicoSetup)."); input("  [Enter] ..."); return
    ok(f"Quelle: {src}")
    shared = pick_target()
    if not shared: bad("Kein Ziel gewaehlt - abgebrochen (nichts veraendert)."); input("  [Enter] ..."); return
    dst = shared / SUBFOLDER; dst.mkdir(parents=True, exist_ok=True)
    ok(f"Ziel:   {dst}")
    excludes = set()
    if input("\n  Grosse Ordner (Tools/Videos) mitkopieren? [J/n] ").strip().lower() in ("n","nein","no"):
        excludes = {"01_TOOLS","03_MEDIA","04_BACKUP_CLONE"}; info("Leichte Kopie.")
    else: info("Vollstaendige Kopie.")
    print("\n  Kopiere ...")
    files, total = copy_tree(src, dst, excludes)
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try: (dst / "_letzte_kopie.txt").write_text(f"Kopie von {src}\nStand: {ts}\nDateien aktualisiert: {files}\n", encoding="utf-8")
    except Exception: pass
    print(); ok(f"Fertig. {files} Datei(en) aktualisiert, {human(total)} uebertragen.")
    info("Am Ziel wurde nichts geloescht. Zum Aktualisieren erneut ausfuehren.")
    input("\n  [Enter] zum Schliessen ...")

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n  Abbruch.")
