// Telegram Polling + Commands. Pipeline + Status.
import TelegramBot   from 'node-telegram-bot-api';
import { config }    from './config.js';
import * as pipeline from './pipeline.js';
import * as notion   from './notion.js';
import * as google   from './google.js';

const bot       = new TelegramBot(config.tg.token, { polling: true });
const isAllowed = id => config.tg.allowed.length === 0 || config.tg.allowed.includes(id);

async function handle(msg, kind, text) {
    const chatId = msg.chat.id;
    if (!isAllowed(msg.from.id)) return bot.sendMessage(chatId, 'nicht autorisiert.');
    if (!text)                   return bot.sendMessage(chatId, `/${kind} <text>`);

    bot.sendChatAction(chatId, 'typing').catch(() => {});
    try {
        const r = await pipeline.process(kind, text);
        const head = [`ok [${r.kind}]`];
        if (r.gtaskId) head.push(`gtask: ${String(r.gtaskId).slice(0, 12)}…`);
        if (r.eventId) head.push(`event: ${String(r.eventId).slice(0, 12)}…`);
        const pretty = JSON.stringify(r.structured, null, 2);
        await bot.sendMessage(
            chatId,
            head.join('\n') + '\n```\n' + pretty + '\n```',
            { parse_mode: 'Markdown' }
        );
    } catch (e) {
        console.error('[bot]', e);
        await bot.sendMessage(chatId, `fehler: ${e.message}`);
    }
}

bot.onText(/^\/task(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'task', (x[1] || '').trim()));
bot.onText(/^\/note(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'note', (x[1] || '').trim()));
bot.onText(/^\/cost(?:\s+([\s\S]+))?$/, (m, x) => handle(m, 'cost', (x[1] || '').trim()));

const HELP = [
    'commands:',
    '  /task <text>  -> Aufgabe (Notion: Tasks; ggf. + Google Tasks/Calendar)',
    '  /note <text>  -> Notiz   (Notion: Memory)',
    '  /cost <text>  -> Ausgabe (Notion: Costs)',
    '  /status       -> Bot-Health',
    '  /help         -> diese Liste',
].join('\n');

bot.onText(/^\/start$/, m => bot.sendMessage(m.chat.id, `zero-friction bot bereit.\n\n${HELP}`));
bot.onText(/^\/help$/,  m => bot.sendMessage(m.chat.id, HELP));

const START = Date.now();
function fmtUptime(ms) {
    const s = Math.floor(ms / 1000);
    const d = Math.floor(s / 86400);
    const h = Math.floor((s % 86400) / 3600);
    const m = Math.floor((s % 3600) / 60);
    return `${d}d ${h}h ${m}m`;
}

bot.onText(/^\/status$/, async msg => {
    const chatId = msg.chat.id;
    if (!isAllowed(msg.from.id)) return bot.sendMessage(chatId, 'nicht autorisiert.');
    const [n, g] = await Promise.all([
        notion.ping(),
        google.enabled() ? google.tokenOk() : Promise.resolve('off'),
    ]);
    const aiMod = config.ai.provider === 'openai' ? config.ai.openai.model : config.ai.claude.model;
    const lines = [
        `uptime  : ${fmtUptime(Date.now() - START)}`,
        `provider: ${config.ai.provider} (${aiMod})`,
        `notion  : ${n}`,
        `google  : ${g}`,
        `webhook : ${config.web.secret ? 'on (port ' + config.web.port + ')' : 'off'}`,
        `allowed : ${config.tg.allowed.length || 'any'}`,
        `node    : ${process.version}`,
    ].join('\n');
    bot.sendMessage(chatId, '```\n' + lines + '\n```', { parse_mode: 'Markdown' });
});

bot.on('polling_error', e => console.error('polling', e.message));
console.log(`[bot] up. provider=${config.ai.provider} allowed=${config.tg.allowed.length || 'any'}`);

export const stopPolling = () => bot.stopPolling({ cancel: true });
