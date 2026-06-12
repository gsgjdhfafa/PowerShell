// AI: aiStructure (kind -> JSON) und aiClassify (text -> {kind, confidence}).
import { request } from 'undici';
import { config } from './config.js';

const STRUCTURE_PROMPT = (kind) => `Du bist ein strikter Strukturierer. Antworte NUR mit JSON.
Schema abhaengig von kind:
  note:     {"title": string, "summary": string, "tags": string[]}
  task:     {"title": string, "due": string|null, "priority": "low"|"med"|"high", "notes": string}
  cost:     {"title": string, "amount": number, "currency": string, "category": string, "notes": string}
  calendar: {"title": string, "due": string, "duration_min": number, "notes": string}
kind = ${kind}. Datum/Uhrzeit als ISO 8601 (UTC oder mit Offset). Kein Fliesstext, kein Markdown, nur JSON.`;

const CLASSIFY_PROMPT = `Du klassifizierst Nutzereingaben oder eingehende Mails.
Antworte NUR mit JSON: {"kind":"note|task|cost|calendar","confidence":0..1}
Heuristik:
- "task"     wenn etwas zu tun ist (mit oder ohne Datum)
- "calendar" wenn ein konkreter Termin/Slot mit Datum + Uhrzeit
- "cost"     wenn Geldbetrag, Quittung, Rechnung
- "note"     fuer alles andere (Idee, Memo, Faktum)`;

async function _callJson(system, user) {
    if (config.ai.provider === 'openai') {
        const { body } = await request('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'authorization': `Bearer ${config.ai.openai.key}`,
                'content-type':  'application/json',
            },
            body: JSON.stringify({
                model: config.ai.openai.model,
                response_format: { type: 'json_object' },
                messages: [
                    { role: 'system', content: system },
                    { role: 'user',   content: user },
                ],
            }),
        });
        const j = await body.json();
        return JSON.parse(j.choices[0].message.content);
    }
    const { body } = await request('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'x-api-key':         config.ai.claude.key,
            'anthropic-version': '2023-06-01',
            'content-type':      'application/json',
        },
        body: JSON.stringify({
            model: config.ai.claude.model,
            max_tokens: 1024,
            system,
            messages: [{ role: 'user', content: user }],
        }),
    });
    const j   = await body.json();
    const raw = j.content?.[0]?.text ?? '{}';
    const m   = raw.match(/\{[\s\S]*\}/);
    return JSON.parse(m ? m[0] : raw);
}

export async function aiStructure(kind, text) {
    return _callJson(STRUCTURE_PROMPT(kind), text);
}

export async function aiClassify(text) {
    const r = await _callJson(CLASSIFY_PROMPT, text);
    const valid = new Set(['note', 'task', 'cost', 'calendar']);
    const kind  = valid.has(r.kind) ? r.kind : 'note';
    const conf  = Number.isFinite(r.confidence) ? r.confidence : 0;
    return { kind: conf < 0.5 ? 'note' : kind, confidence: conf };
}
