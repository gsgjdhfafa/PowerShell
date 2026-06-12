# CLAUDE-Regeln fuer dieses Projekt

Durable Anweisungen fuer Claude Code, wenn jemand in `setup/` arbeitet.

## Datei-Struktur

- **Kapitel/Sektionen sind Pflicht.** Jede neue Datei (Markdown, Skripte, Code-Module > ~50 Zeilen) bekommt klare Kapitel-Ueberschriften, sobald es eine sinnvolle Trennung gibt. Lieber **eine Ueberschrift zu viel** als ein Wall-of-Text.
- Markdown: `#`/`##`/`###` mit Inhaltsverzeichnis (TOC) ab ~5 Sektionen.
- Skripte: Kommentar-Banner pro logischem Block (`# --- 1. Block ---`).
- Code-Module: thematisch trennen (`config.js`, `pipeline.js`, `server.js` statt einer fetten `bot.js`).

## Sprache + Stil

- **Deutsch zuerst.** Englische Fachbegriffe in (Klammern) erklaeren beim ersten Auftreten.
- Praktisch, idiotensicher, mit konkreten Befehlen die man kopieren kann. Keine Theorie.
- Keine Emojis ausser explizit gewuenscht.
- Account-Kontext angeben wo relevant (z.B. „Gerrit (Master)" hinter Hotkey-Targets).

## Code-Stil

- **Idempotent**: Skripte muessen mehrfach ausfuehrbar sein, ohne kaputtzugehen.
- **Copy-paste tauglich**: keine `<placeholder>`-Versteckspielchen, falls Variablen anpassbar — als ENV-Var oder klar markiert.
- Keine GUI-Anleitungen wo CLI geht.
- Tools moeglichst ohne neue Dependencies — pure Standard-Bibliothek/Native bevorzugen.

## Workflow

- Auf User-Anfragen direkt antworten + ausfuehren, nicht 3 Klarungen einschieben.
- Bei mehreren Schritten: gepushter Commit pro logischer Einheit.
- Gefahrliche Aktionen (force-push, branch-delete, PR-merge) nur nach expliziter Freigabe.
- Nach jedem Block: `setup/PROGRESS.md` aktualisieren (Haken setzen).

## Tracker

- `setup/PROGRESS.md` ist der Live-Tracker. Bei jedem groesseren Schritt Haken setzen + Commit-Hash in der Historie nachtragen.
