# 05-vr · Use-Cases & Profil-Match

Recherche-Ergebnis: wo dieses Setup (Telegram-Bot + VPS + Claude/OpenAI + Notion + PICO 4 Ultra als VR-Client) sich in der breiteren Landschaft 2026 einsortiert, was sich anderswo als nuetzlich bewaehrt hat, und welche Profile am meisten davon profitieren.

Stand: Juni 2026.

---

## A · Vergleichbare Setups die schon umgesetzt wurden

**Open-Source-Templates:**

| Repo | Was es macht |
|---|---|
| `kaymen99/personal-ai-assistant` | Multi-Agent, Telegram/Slack/WhatsApp, Mail+Kalender+Tasks |
| `CreatmanCEO/notion-knowledge-assistant` | Self-hosted NotebookLM-Klon, Notion-RAG mit Zitaten |
| `smixs/agent-second-brain` | Voice → Todoist + KB, Ebbinghaus-Decay-Memory |
| `nova4u/chatgpt-supabase-telegram-bot` | Supabase statt Notion, Edge-Function-Deployment |
| `muety/telegram-expense-bot` | Single-purpose Cost-Tracking |
| `xheiop/notion-telegram-bot` | Minimaler Notion-DB-Bot |

**No-Code-Standard:** n8n dominiert. `enescingoz/awesome-n8n-templates` (280+ Workflows). Top-Templates: #7925 Voice→Task+Notion, #11817 Voice-To-Do, #11368 Expense+OCR, #4188 Telegram→Notion mit DeepSeek+Whisper, #4862 Mood+Weather. Hosted via Hostinger Clawdbot / OpenClaw (One-Click VPS). Paid: Kris Ograbek "Voice→Notion Capture" (Gumroad).

**Konsens-Tooling:**
- Orchestrierung: n8n, Make, Pipedream
- Hosting: Hetzner-VPS+Docker, Railway, Fly.io, Hostinger, Cloudflare Workers
- Memory: Notion (#1), Supabase, Obsidian, Airtable
- STT/LLM: Whisper, GPT-4o, Claude Sonnet/Opus 4.x, Gemini, DeepSeek, OpenRouter

**Schools of Thought:**
- Tiago Forte (BASB → AI Second Brain, Pivot Feb 2026)
- August Bradley (PPV + AI Coaches)
- Ali Abdaal (Notion + Todoist + Readwise + NotebookLM)

→ **Unser Stack sitzt im Mainstream.** Keine Re-Invents noetig.

---

## B · Use-Cases die sich bewaehrt haben (vs. Hype)

**Bewaehrt:**
1. Voice-Memo → strukturierter Notion/Todoist-Eintrag (Whisper + LLM) — **#1 robustester Use-Case der Branche**
2. Expense-Tracking (Foto/Voice + OCR + GPT-4o)
3. Task-Capture / GTD-Inbox via Telegram
4. Readwise/Reader-Highlights → Notion
5. Daily Mood-Log (longitudinal auswertbar)

**Hype, abgekuehlt:**
- Personal-CRM-Agents (Latency, Trust-Probleme)
- Self-hosted Rosebud/Reflectly-Klone (SaaS-Markt geschlossen)
- All-in-one "Jarvis"-Repos (zu breit, brechen an Auth/Reliability)
- Komplette Mail-Triage-Agents (Spam-/False-Positive-Risiko)

---

## C · VR-Productivity-Stand 2026

**PICO 4 Ultra konkret:**
- PanoScreen Workspace (native 360° MR-Multitasking)
- PICO OS 6: Eye-and-pinch, Controller, Motion-Tracker, Keyboard/Mouse
- Voice-Input nativ in 15 Sprachen (Deutsch dabei)
- PICO Connect: Mac/Windows/iOS/Android-Mirroring, bis zu 3 Desktops parallel
- Roadmap: "Project Swan" als 2026-Flagship-Nachfolger
- Klare Business-Positionierung

**Etablierte VR-Productivity-Tools:**
- Immersed (Multi-Monitor in VR, Standard fuer Remote-Worker)
- Virtual Desktop (PC-Streaming)
- Horizon Workrooms (Meeting-fokus, eingeschlafen)
- Spatial.io / vSpatial
- visionOS App-Katalog 2026 reicht fuer Full-Workweek

**VR + KI + Voice — Forschung/Indie:**
- `Gustorvo/ChatGPT-VR` (GitHub-Experiment)
- GPT-VR Nexus (IEEE VR 2024 Demo, Penn State)
- Kirill Markin: Voice-enabled Telegram Bot for GPT (Medium) — exakt unser Pattern, nur ohne VR

**VR-Productivity — was sich haelt:**
1. Multi-Monitor-Ersatz auf Reisen
2. Privacy-Bubble fuer sensible Calls/Schreibarbeit
3. Haendefreies Voice-Diktat (Walking-Pad-Kombo)
4. Immersives Journaling (FloatVR zeigt Retention)
5. Focus-Sessions ohne Smartphone-Sichtkontakt

**Was nicht funktioniert:**
- Horizon Workrooms als "VR-Office"
- Avatar-Collaboration ausserhalb Niche
- WebXR-Dashboards (kein ROI)
- Komplette Tagesarbeit in VR (Heat, Battery, Augen)

---

## D · Reversiv — fuer welche Profile passt das Setup besonders?

Setup-Signatur: **single-user, voice-first, cloud-only, haendefrei, ohne Smartphone-Distraction, persistentes AI-Memory in Notion.**

**Starker Fit:**

| Profil | Warum dieses Setup ideal ist |
|---|---|
| ADHS / Reizfilter-Probleme | Voice eliminiert Tipp-Hemmschwelle, VR-Bubble eliminiert visuelle Reize, Single-Inbox eliminiert App-Switching. Studien (npj Digital Medicine 2026): ≥8 Wochen VR-Intervention verbessert Symptome, Executive Function, Emotion-Regulation. |
| Solo-Founder / Operator-Mode | Ein Brain-Dump-Punkt, KI strukturiert, Notion als persistentes Memory, kein Tool-Sprawl |
| Digital Nomaden | Headset = portabler Monitor, VPS = geraeteunabhaengig, alles cloud |
| Writers / Long-form-Creators | Voice-Diktat + Strukturierung + Notion. VR-Bubble als Schreib-Kokon |
| Trauma-/Reflection-Journaling | Voice ist weniger blockierend als Tippen, Notion archiviert longitudinal |
| Disability Support (motorisch) | Komplett haendefrei (Voice + Eye-Tracking + Pinch) |
| Privacy-Profile | Eigene VPS, single-User-Lock, kein SaaS-Tracker |
| Deep-Work-Profile | Distraction-frei by design, Voice-Capture ohne Context-Switch |

**Schwacher Fit:**
- Teams >1 (single-user-by-design)
- Slack-heavy Synchron-Kommunikation
- Workflows mit strukturierten Formular-Inputs
- Profile ohne Geduld fuer 2-5s Bot-Latency

**Killer-Combos die in der Recherche auftauchen:**
- VR + Walking-Pad + Voice-Diktat → "moving knowledge work" Trend 2026
- VR + Telegram-Bot Tagesreflektion → ADHS-/Therapie-Niche
- VR + Single-Inbox + Cloud-Notion → Nomaden, Solo-Founders

---

## E · Abgeleitete Roadmap-Prioritaeten

Aus der Recherche, sortiert nach validierter-Nutzen / Aufwand:

1. **Whisper-Integration** (Voice → strukturierter Notion-Eintrag) — #1 validierter Use-Case der Branche
2. **Daily Reflection Prompt** (Cron 21:00, Frage in Telegram, Antwort → Notion Memory)
3. **Readwise/Reader → Notion Highlights-Sync** (Ali-Abdaal-Standard)
4. **Expense-Tracking-Command** um Foto-Upload + OCR (GPT-4o Vision) erweitern
5. **Wochen-Review-Bot** (sonntags KI-Summary aller Memory-Eintraege)

**NICHT bauen (Hype-Falle aus der Recherche):**
- Personal-CRM-Agent
- Mail-Triage-Agent
- Avatar-/3D-VR-Dashboard
- WebXR-eigenentwicklung

---

## Quellen

- [Pico 4 Ultra Enterprise Review 2026 — VR Expert](https://vrx.vr-expert.com/pico-4-ultra-enterprise-review-2026/)
- [PICO XR PICO OS 6 / Project Swan](https://www.knoxlabs.com/blogs/vr-xr-news/pico-xr-unveils-pico-os-6-and-previews-2026-flagship-project-swan)
- [GPT-VR Nexus — IEEE VR 2024 Demo](https://bpb-us-e1.wpmucdn.com/sites.psu.edu/dist/a/136919/files/2024/02/IEEE_VR_2024_Demo_GPT_VR-70f2aedfe3007320.pdf)
- [Kirill Markin: Voice-enabled Telegram Bot for GPT Chat without DevOps](https://kirill-markin.medium.com/creating-a-voice-enabled-telegram-bot-for-gpt-chat-without-devops-a-comprehensive-guide-8a905241cb9c)
- [VR Interventions for ADHD — npj Digital Medicine 2026](https://www.nature.com/articles/s41746-026-02505-9)
- [FloatVR — Meta Quest Store](https://www.meta.com/experiences/floatvr-relaxation-and-focus-sleep-anxiety-adhd/5716140881752678/)
- [Best Voice Dictation Apps for ADHD — Willowvoice 2026](https://willowvoice.com/blog/best-voice-dictation-apps-adhd-neurodivergent-users)
- [awesome-n8n-templates Repo](https://github.com/enescingoz/awesome-n8n-templates)
