// Notion: createPage / updatePage + saveNote/Task/Cost + Property-Helpers.
import { request } from 'undici';
import { config } from './config.js';

export const T = {
    title: v => ({ title:     [{ text: { content: String(v ?? '').slice(0, 2000) } }] }),
    rich:  v => ({ rich_text: [{ text: { content: String(v ?? '').slice(0, 2000) } }] }),
    num:   v => ({ number: Number(v ?? 0) }),
    sel:   v => v ? { select: { name: String(v) } } : { select: null },
    multi: a => ({ multi_select: (a || []).map(n => ({ name: String(n) })) }),
    date:  v => v ? { date: { start: v } } : { date: null },
};

async function notionFetch(method, path, body) {
    const opts = {
        method,
        headers: {
            'authorization':   `Bearer ${config.notion.token}`,
            'notion-version':  '2022-06-28',
        },
    };
    if (body !== undefined) {
        opts.headers['content-type'] = 'application/json';
        opts.body = JSON.stringify(body);
    }
    const { body: rb, statusCode } = await request(`https://api.notion.com/v1${path}`, opts);
    const j = await rb.json();
    if (statusCode >= 300) throw new Error(`Notion ${statusCode}: ${JSON.stringify(j)}`);
    return j;
}

export const createPage = (dbId, properties) =>
    notionFetch('POST', '/pages', { parent: { database_id: dbId }, properties });

export const updatePage = (pageId, properties) =>
    notionFetch('PATCH', `/pages/${pageId}`, { properties });

export async function ping() {
    try {
        await notionFetch('GET', '/users/me');
        return 'ok';
    } catch (e) {
        return `fail (${e.message})`;
    }
}

export function saveNote(o) {
    return createPage(config.notion.db.note, {
        Name:    T.title(o.title),
        Summary: T.rich(o.summary),
        Tags:    T.multi(o.tags),
    });
}

export function saveTask(o) {
    return createPage(config.notion.db.task, {
        Name:     T.title(o.title),
        Due:      T.date(o.due),
        Priority: T.sel(o.priority),
        Notes:    T.rich(o.notes),
    });
}

export function saveCost(o) {
    const amount = Number(o.amount);
    if (!Number.isFinite(amount)) {
        throw new Error('cost: amount fehlt oder ist keine Zahl. /cost mit Betrag wiederholen.');
    }
    return createPage(config.notion.db.cost, {
        Name:     T.title(o.title),
        Amount:   { number: amount },
        Currency: T.sel(o.currency),
        Category: T.sel(o.category),
        Notes:    T.rich(o.notes),
    });
}
