// Google APIs (Tasks + Calendar) ueber undici. Keine googleapis-Dep.
// Lazy OAuth2 Refresh, Access-Token Cache.
import { request } from 'undici';
import { config } from './config.js';

let _token   = null;
let _expires = 0;

async function getAccessToken() {
    if (_token && Date.now() < _expires - 60_000) return _token;
    const params = new URLSearchParams({
        client_id:     config.google.clientId,
        client_secret: config.google.clientSecret,
        refresh_token: config.google.refreshToken,
        grant_type:    'refresh_token',
    });
    const { body, statusCode } = await request('https://oauth2.googleapis.com/token', {
        method:  'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body:    params.toString(),
    });
    const j = await body.json();
    if (statusCode >= 300) throw new Error(`google token ${statusCode}: ${j.error || ''}`);
    _token   = j.access_token;
    _expires = Date.now() + (Number(j.expires_in || 3600) * 1000);
    return _token;
}

async function gFetch(method, url, body) {
    const tok = await getAccessToken();
    const opts = { method, headers: { authorization: `Bearer ${tok}` } };
    if (body !== undefined) {
        opts.headers['content-type'] = 'application/json';
        opts.body = JSON.stringify(body);
    }
    const { body: rb, statusCode } = await request(url, opts);
    const j = await rb.json();
    if (statusCode >= 300) throw new Error(`google ${statusCode}: ${j.error?.message || ''}`);
    return j;
}

export async function insertTask({ title, notes, due }) {
    if (!config.google.tasksListId) throw new Error('GOOGLE_TASKS_LIST_ID fehlt');
    const url = `https://tasks.googleapis.com/tasks/v1/lists/${encodeURIComponent(config.google.tasksListId)}/tasks`;
    const b = { title: String(title || '').slice(0, 1024) };
    if (notes) b.notes = String(notes).slice(0, 8192);
    if (due)   b.due   = new Date(due).toISOString();
    return gFetch('POST', url, b);
}

export async function insertEvent({ summary, description, start, end }) {
    const url = `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(config.google.calendarId)}/events`;
    const s = new Date(start);
    const e = end ? new Date(end) : new Date(s.getTime() + 60 * 60 * 1000);
    return gFetch('POST', url, {
        summary:     String(summary || '').slice(0, 1024),
        description: String(description || '').slice(0, 8192),
        start:       { dateTime: s.toISOString() },
        end:         { dateTime: e.toISOString() },
    });
}

export async function tokenOk() {
    try { await getAccessToken(); return 'ok'; }
    catch (e) { return `fail (${e.message})`; }
}

export const enabled = () => config.google.enabled;
