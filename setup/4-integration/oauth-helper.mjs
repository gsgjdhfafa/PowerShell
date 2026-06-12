// One-Shot OAuth-Helper fuer Google Tasks + Calendar.
// Lokal ausfuehren:  node setup/4-integration/oauth-helper.mjs
// Voraussetzung: in Google Cloud Console OAuth-Client "Desktop App" angelegt.
// Druckt am Ende einen .env-Block zum Reinkopieren.

import http     from 'node:http';
import readline from 'node:readline';
import { exec } from 'node:child_process';

const PORT  = 53672;
const REDIR = `http://127.0.0.1:${PORT}/cb`;
const SCOPES = [
    'https://www.googleapis.com/auth/tasks',
    'https://www.googleapis.com/auth/calendar.events',
].join(' ');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const ask = (q) => new Promise(r => rl.question(q, r));

function openUrl(url) {
    const cmd = process.platform === 'darwin' ? `open "${url}"`
              : process.platform === 'win32'  ? `start "" "${url}"`
              : `xdg-open "${url}"`;
    exec(cmd, () => {});
}

function awaitCallback() {
    return new Promise((resolve, reject) => {
        const server = http.createServer((req, res) => {
            const u = new URL(req.url, `http://127.0.0.1:${PORT}`);
            if (u.pathname !== '/cb') { res.writeHead(404).end(); return; }
            const code = u.searchParams.get('code');
            const err  = u.searchParams.get('error');
            res.writeHead(200, { 'content-type': 'text/plain' });
            res.end(err ? `error: ${err}\nDu kannst den Tab schliessen.` : 'ok. Tab schliessen.');
            server.close();
            err ? reject(new Error(err)) : resolve(code);
        });
        server.listen(PORT, '127.0.0.1');
    });
}

async function exchange(code, clientId, clientSecret) {
    const body = new URLSearchParams({
        code, client_id: clientId, client_secret: clientSecret,
        redirect_uri: REDIR, grant_type: 'authorization_code',
    });
    const r = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body,
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`token ${r.status}: ${JSON.stringify(j)}`);
    return j;
}

async function listTaskLists(accessToken) {
    const r = await fetch('https://tasks.googleapis.com/tasks/v1/users/@me/lists', {
        headers: { authorization: `Bearer ${accessToken}` },
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`tasklists ${r.status}: ${JSON.stringify(j)}`);
    return j.items || [];
}

const clientId     = (await ask('GOOGLE_CLIENT_ID:     ')).trim();
const clientSecret = (await ask('GOOGLE_CLIENT_SECRET: ')).trim();
rl.close();

const authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?' + new URLSearchParams({
    client_id: clientId, redirect_uri: REDIR, response_type: 'code',
    access_type: 'offline', prompt: 'consent', scope: SCOPES,
}).toString();

console.log('\nOeffne falls noetig manuell:\n  ' + authUrl + '\n');
openUrl(authUrl);

const code   = await awaitCallback();
const tokens = await exchange(code, clientId, clientSecret);
if (!tokens.refresh_token) {
    console.error('\nKein refresh_token erhalten. Tipp: in Google Account -> Sicherheit -> "Drittanbieter-Zugriff" den Eintrag entfernen und nochmal starten.');
    process.exit(1);
}

let lists = [];
try { lists = await listTaskLists(tokens.access_token); }
catch (e) { console.warn('[warn] tasklists:', e.message); }

console.log('\n--- in setup/3-bot/.env eintragen ---');
console.log(`GOOGLE_CLIENT_ID=${clientId}`);
console.log(`GOOGLE_CLIENT_SECRET=${clientSecret}`);
console.log(`GOOGLE_REFRESH_TOKEN=${tokens.refresh_token}`);
if (lists.length) {
    console.log(`GOOGLE_TASKS_LIST_ID=${lists[0].id}    # ${lists[0].title}`);
    if (lists.length > 1) {
        console.log('\n# weitere Listen:');
        for (const l of lists.slice(1)) console.log(`# ${l.id}    ${l.title}`);
    }
} else {
    console.log('GOOGLE_TASKS_LIST_ID=    # keine Liste gefunden, einmal in Google Tasks eine anlegen');
}
console.log('GOOGLE_CALENDAR_ID=primary');
