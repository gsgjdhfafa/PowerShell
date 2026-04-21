// ============================================================
// AI-Layer: OpenAI + Claude
// Eingang: Rohtext vom User
// Ausgang: strukturiertes JSON { type, title, content, cost? }
// ============================================================
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';

const openai    = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SYSTEM_PROMPT = `Du bist ein Strukturierer.
Input: freier Text vom User.
Output: reines JSON, keine Markdown-Fences, kein Prosa.

Schema:
{
  "type":    "task" | "note" | "cost",
  "title":   string,
  "content": string,
  "amount":  number | null,     // nur bei type=cost, in EUR
  "tags":    string[]
}

Regeln:
- type strikt einer der drei Werte
- amount nur bei cost, sonst null
- tags maximal 5, lowercase, single-word
- keine Erklaerungen`;

export async function structureWithOpenAI(text, hint) {
    const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
    const r = await openai.chat.completions.create({
        model,
        response_format: { type: 'json_object' },
        messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user',   content: `HINT=${hint}\n\n${text}` }
        ],
        temperature: 0.2
    });
    return JSON.parse(r.choices[0].message.content);
}

export async function structureWithClaude(text, hint) {
    const model = process.env.ANTHROPIC_MODEL || 'claude-sonnet-4-6';
    const r = await anthropic.messages.create({
        model,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: [
            { role: 'user', content: `HINT=${hint}\n\n${text}\n\nAntwort nur als JSON-Objekt.` }
        ]
    });
    const raw = r.content.find(c => c.type === 'text')?.text ?? '{}';
    const clean = raw.replace(/^```(?:json)?|```$/g, '').trim();
    return JSON.parse(clean);
}

// Claude ist Default, OpenAI ist Fallback
export async function structure(text, hint = 'auto') {
    try {
        return await structureWithClaude(text, hint);
    } catch (e) {
        console.warn('[ai] claude failed, fallback openai:', e.message);
        return await structureWithOpenAI(text, hint);
    }
}
