// Bootstrap: config validieren, bot + server starten, graceful shutdown.
import { config }                   from './config.js';
import { stopPolling }              from './bot.js';
import { startServer }              from './server.js';
import { parseWorkerPayload, buildMailText } from './mail.js';
import { classifyAndProcess }       from './classifier.js';

const VERSION = process.env.APP_VERSION || 'dev';

let server = null;

async function main() {
    server = await startServer({
        version: VERSION,
        onMail: async (payload) => {
            const parsed = parseWorkerPayload(payload);
            const text   = buildMailText(parsed);
            if (!text) { console.warn('[mail] leerer body, ignoriert'); return; }
            const r = await classifyAndProcess(text);
            const fromHash = parsed.from ? parsed.from.split('@')[1] || 'unknown' : 'unknown';
            console.log(`[mail] from=${fromHash} kind=${r.kind} conf=${(r.confidence ?? 0).toFixed(2)} page=${r.pageId}`);
        },
    });
    void config; // bot.js hat schon polling gestartet, config bereits validiert.
}

main().catch(e => {
    console.error('[fatal]', e);
    process.exit(1);
});

let shuttingDown = false;
async function shutdown() {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log('[shutdown] stopping');
    try { await stopPolling(); } catch (e) { console.error(e); }
    try { server && server.close(); } catch (e) { console.error(e); }
    setTimeout(() => process.exit(0), 1000).unref();
}
process.on('SIGTERM', shutdown);
process.on('SIGINT',  shutdown);
process.on('unhandledRejection', e => console.error('[unhandled]', e));
