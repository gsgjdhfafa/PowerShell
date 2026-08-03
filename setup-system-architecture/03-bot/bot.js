// ============================================================
// Telegram Bot - Einstiegspunkt
// Flow: Telegram -> Bot -> KI -> Notion -> Antwort Telegram
// Commands: /task, /note, /cost
// Jede freie Nachricht => auto-strukturiert
// ============================================================
import 'dotenv/config';
import TelegramBot from 'node-telegram-bot-api';
import { structure } from '../04-integration/ai.js';
import { saveToNotion } from '../04-integration/notion.js';

const TOKEN     = process.env.TELEGRAM_BOT_TOKEN;
const ALLOWED   = String(process.env.TELEGRAM_ALLOWED_USER_ID || '').trim();

if (!TOKEN)   throw new Error('TELEGRAM_BOT_TOKEN fehlt');
if (!ALLOWED) throw new Error('TELEGRAM_ALLOWED_USER_ID fehlt');

const bot = new TelegramBot(TOKEN, { polling: true });

function authorized(msg) {
    return String(msg.from.id) === ALLOWED;
}

async function handle(msg, hint) {
    if (!authorized(msg)) {
        console.log(`[bot] blockiert: Absender-ID ${msg.from.id} != TELEGRAM_ALLOWED_USER_ID (${ALLOWED})`);
        return;
    }
    const chatId = msg.chat.id;
    const text   = (msg.text || '').replace(/^\/\w+\s*/, '').trim();
    if (!text) {
        await bot.sendMessage(chatId, 'Leer. Text mitgeben.');
        return;
    }
    try {
        await bot.sendChatAction(chatId, 'typing');
        const entry = await structure(text, hint);
        if (hint !== 'auto') entry.type = hint;     // explizit erzwingen
        const url = await saveToNotion(entry);
        await bot.sendMessage(
            chatId,
            `ok [${entry.type}] ${entry.title}\n${url}`,
            { disable_web_page_preview: true }
        );
    } catch (e) {
        console.error('[bot]', e);
        await bot.sendMessage(chatId, `err: ${e.message}`);
    }
}

bot.onText(/^\/start$/,           m => bot.sendMessage(m.chat.id, 'ready. /task /note /cost oder freier Text.'));
bot.onText(/^\/task(?:\s|$)/i,    m => handle(m, 'task'));
bot.onText(/^\/note(?:\s|$)/i,    m => handle(m, 'note'));
bot.onText(/^\/cost(?:\s|$)/i,    m => handle(m, 'cost'));

bot.on('message', m => {
    if (!m.text || m.text.startsWith('/')) return;
    handle(m, 'auto');
});

bot.on('polling_error', e => console.error('[polling]', e.code, e.message));

console.log('[bot] up');
