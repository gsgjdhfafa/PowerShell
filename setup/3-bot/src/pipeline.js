// Pipeline: structure -> save -> google -> backfill IDs in Notion.
import { aiStructure } from './ai.js';
import * as notion     from './notion.js';
import * as google     from './google.js';

export async function process(kind, text) {
    const structured = await aiStructure(kind, text);

    if (kind === 'note') {
        const page = await notion.saveNote(structured);
        return { kind, structured, pageId: page.id };
    }
    if (kind === 'cost') {
        const page = await notion.saveCost(structured);
        return { kind, structured, pageId: page.id };
    }

    // task | calendar -> immer als Notion-Task speichern (Source of Truth)
    const page = await notion.saveTask({
        title:    structured.title,
        due:      structured.due ?? null,
        priority: structured.priority || 'med',
        notes:    structured.notes    || '',
    });

    let gtaskId = null;
    let eventId = null;

    if (google.enabled()) {
        if (kind === 'task') {
            try {
                const t = await google.insertTask({
                    title: structured.title,
                    notes: structured.notes,
                    due:   structured.due,
                });
                gtaskId = t.id;
            } catch (e) { console.error('[gtask]', e.message); }
        }
        if (structured.due) {
            try {
                const durMin = Number(structured.duration_min) || 60;
                const start  = new Date(structured.due);
                const end    = new Date(start.getTime() + durMin * 60_000);
                const ev     = await google.insertEvent({
                    summary:     structured.title,
                    description: structured.notes,
                    start, end,
                });
                eventId = ev.id;
            } catch (e) { console.error('[gcal]', e.message); }
        }

        const upd = {};
        if (gtaskId) upd.GTaskId = notion.T.rich(gtaskId);
        if (eventId) upd.EventId = notion.T.rich(eventId);
        if (Object.keys(upd).length) {
            try { await notion.updatePage(page.id, upd); }
            catch (e) { console.error('[notion-update]', e.message); }
        }
    }

    return { kind, structured, pageId: page.id, gtaskId, eventId };
}
