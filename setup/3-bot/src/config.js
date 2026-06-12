// Zentrale ENV-Konfiguration. Einziger Konsument von process.env.
const env = (k, d) => {
    const v = process.env[k];
    if (v === undefined || v === '') return d === undefined ? null : d;
    return v;
};

const missing = [];
const need = (k) => {
    const v = env(k);
    if (v === null) missing.push(k);
    return v;
};

const tg = {
    token: need('TELEGRAM_BOT_TOKEN'),
    allowed: (env('TELEGRAM_ALLOWED_USER_IDS', '') || '')
        .split(',').map(s => s.trim()).filter(Boolean).map(Number),
};

const ai = {
    provider: (env('AI_PROVIDER', 'claude') || 'claude').toLowerCase(),
    openai:   { key: env('OPENAI_API_KEY', ''),    model: env('OPENAI_MODEL', 'gpt-4o-mini') },
    claude:   { key: env('ANTHROPIC_API_KEY', ''), model: env('CLAUDE_MODEL', 'claude-opus-4-7') },
};
if (!ai.openai.key && !ai.claude.key)              missing.push('OPENAI_API_KEY oder ANTHROPIC_API_KEY');
if (ai.provider === 'openai' && !ai.openai.key)    missing.push('OPENAI_API_KEY (provider=openai)');
if (ai.provider === 'claude' && !ai.claude.key)    missing.push('ANTHROPIC_API_KEY (provider=claude)');

const notion = {
    token: need('NOTION_TOKEN'),
    db: {
        note: need('NOTION_DB_MEMORY'),
        task: need('NOTION_DB_TASKS'),
        cost: need('NOTION_DB_COSTS'),
    },
};

const google = {
    clientId:     env('GOOGLE_CLIENT_ID', ''),
    clientSecret: env('GOOGLE_CLIENT_SECRET', ''),
    refreshToken: env('GOOGLE_REFRESH_TOKEN', ''),
    tasksListId:  env('GOOGLE_TASKS_LIST_ID', ''),
    calendarId:   env('GOOGLE_CALENDAR_ID', 'primary'),
};
google.enabled = Boolean(google.clientId && google.clientSecret && google.refreshToken);

const web = {
    port:   Number(env('WEBHOOK_PORT', '8080')),
    secret: env('WEBHOOK_SECRET', '') || '',
};
if (web.secret && web.secret.length < 32) missing.push('WEBHOOK_SECRET (>=32 Zeichen)');

if (missing.length) {
    console.error('[config] fehlende ENV:\n  - ' + missing.join('\n  - '));
    process.exit(1);
}

if (!web.secret)      console.warn('[config] WEBHOOK_SECRET nicht gesetzt -> /mail liefert 503');
if (!google.enabled)  console.warn('[config] Google nicht konfiguriert -> Tasks/Calendar Sync aus');

export const config = Object.freeze({ tg, ai, notion, google, web });
