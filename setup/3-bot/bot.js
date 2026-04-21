// Zero-Friction Telegram Bot
// Commands: /task  /note  /cost
// Pipeline: Telegram -> KI (OpenAI|Claude) -> Notion -> Telegram
import TelegramBot from 'node-telegram-bot-api';
import { request } from 'undici';

const env = (k, d = undefined) => {
    const v = process.env[k];
    if (v === undefined || v === '') {
        if (d !== undefined) return d;
        throw new Error(`ENV ${k} fehlt`);
    }
    return v;
};

const TG_TOKEN     = env('TELEGRAM_BOT_TOKEN');
const ALLOWED      = env('TELEGRAM_ALLOWED_USER_IDS', '')
                        .split(',').map(s => s.trim()).filter(Boolean).map(Number);
const PROVIDER     = env('AI_PROVIDER', 'claude').toLowerCase();
const OPENAI_KEY   = process.env.OPENAI_API_KEY     || '';
const CLAUDE_KEY   = process.env.ANTHROPIC_API_KEY  || '';
const OPENAI_MODEL = env('OPENAI_MODEL', 'gpt-4o-mini');
const CLAUDE_MODEL = env('CLAUDE_MODEL', 'claude-opus-4-7');
const NOTION_TOKEN = env('NOTION_TOKEN');
const DB = {
    note: env('NOTION_DB_MEMORY'),
    task: env('NOTION_DB_TASKS'),
    cost: env('NOTION_DB_COSTS'),
};

const bot = new TelegramBot(TG_TOKEN, { polling: true });

const isAllowed = id => ALLOWED.length === 0 || ALLOWED.includes(id);

// --- KI -----------------------------------------------------------------------
async function aiStructure(kind, text) {
    const system = `Du bist ein strikter Strukturierer. Antworte NUR mit JSON.
Schema abhaengig von kind:
  note: {"title": string, "summary": string, "tags": string[]}
  task: {"title": string, "due": string|null, "priority": "low"|"med"|"high", "notes": string}
  cost: {"title": string, "amount": number, "currency": string, "category": string, "notes": string}
kind = ${kind}. Kein Fliesstext, kein Markdown, nur JSON.`;

    if (PROVIDER === 'openai') {
        if (!OPENAI_KEY) throw new Error('OPENAI_API_KEY fehlt');
        const { body } = await request('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'authorization': `Bearer ${OPENAI_KEY}`,
                'content-type': 'application/json',
            },
            body: JSON.stringify({
                model: OPENAI_MODEL,
                response_format: { type: 'json_object' },
                messages: [
                    { role: 'system', content: system },
                    { role: 'user',   content: text },
                ],
            }),
        });
        const j = await body.json();
        return JSON.parse(j.choices[0].message.content);
    }

    if (!CLAUDE_KEY) throw new Error('ANTHROPIC_API_KEY fehlt');
    const { body } = await request('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'x-api-key': CLAUDE_KEY,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
        },
        body: JSON.stringify({
            model: CLAUDE_MODEL,
            max_tokens: 1024,
            system,
            messages: [{ role: 'user', content: text }],
        }),
    });
    const j = await body.json();
    const raw = j.content?.[0]?.text ?? '{}';
    const m = raw.match(/\{[\s\S]*\}/);
    return JSON.parse(m ? m[0] : raw);
}

// --- Notion -------------------------------------------------------------------
async function notionCreate(dbId, properties) {
    const { body, statusCode } = await request('https://api.notion.com/v1/pages', {
        method: 'POST',
        headers: {
            'authorization': `Bearer ${NOTION_TOKEN}`,
            'notion-version': '2022-06-28',
            'content-type': 'application/json',
        },
        body: JSON.stringify({ parent: { database_id: dbId }, properties }),
    });
    const j = await body.json();
    if (statusCode >= 300) throw new Error(`Notion ${statusCode}: ${JSON.stringify(j)}`);
    return j;
}

const T = {
    title: v => ({ title: [{ text: { content: String(v ?? '').slice(0, 2000) } }] }),
    rich:  v => ({ rich_text: [{ text: { content: String(v ?? '').slice(0, 2000) } }] }),
    num:   v => ({ number: Number(v ?? 0) }),
    sel:   v => v ? { select: { name: String(v) } } : { select: null },
    multi: a => ({ multi_select: (a || []).map(n => ({ name: String(n) })) }),
    date:  v => v ? { date: { start: v } } : { date: null },
};

async function saveNote(o) {
    return notionCreate(DB.note, {
        Name:    T.title(o.title),
        Summary: T.rich(o.summary),
        Tags:    T.multi(o.tags),
    });
}
async function saveTask(o) {
    return notionCreate(DB.task, {
        Name:     T.title(o.title),
        Due:      T.date(o.due),
        Priority: T.sel(o.priority),
        Notes:    T.rich(o.notes),
    });
}
async function saveCost(o) {
    return notionCreate(DB.cost, {
        Name:     T.title(o.title),
        Amount:   T.num(o.amount),
        Currency: T.sel(o.currency),
        Category: T.sel(o.category),
        Notes:    T.rich(o.notes),
    });
}

// --- Handler ------------------------------------------------------------------
async function handle(msg, kind, text) {
    const chatId = msg.chat.id;
    if (!isAllowed(msg.from.id)) return bot.sendMessage(chatId, 'nicht autorisiert.');
    if (!text) return bot.sendMessage(chatId, `/${kind} <text>`);

    await bot.sendChatAction(chatId, 'typing');
    try {
        const s = await aiStructure(kind, text);
        if (kind === 'note') await saveNote(s);
        if (kind === 'task') await saveTask(s);
        if (kind === 'cost') await saveCost(s);
        const pretty = JSON.stringify(s, null, 2);
        await bot.sendMessage(chatId, `ok [${kind}]\n\`\`\`\n${pretty}\n\`\`\``, { parse_mode: 'Markdown' });
    } catch (e) {
        console.error(e);
        await bot.sendMessage(chatId, `fehler: ${e.message}`);
    }
}

bot.onText(/^\/task(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'task', (x[1] || '').trim()));
bot.onText(/^\/note(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'note', (x[1] || '').trim()));
bot.onText(/^\/cost(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'cost', (x[1] || '').trim()));

bot.onText(/^\/start$/, m =>
    bot.sendMessage(m.chat.id, 'zero-friction bot bereit.\n/task <text>\n/note <text>\n/cost <text>'));

bot.on('polling_error', e => console.error('polling', e.message));
console.log(`[bot] up. provider=${PROVIDER} allowed=${ALLOWED.length || 'any'}`);
