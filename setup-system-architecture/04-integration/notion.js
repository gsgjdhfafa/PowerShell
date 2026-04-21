// ============================================================
// Notion-Layer
// 3 Datenbanken: Memory, Tasks, Costs
// Erwartete Properties (Notion):
//   Memory:  Title (title), Tags (multi_select), Content (rich_text)
//   Tasks:   Title (title), Status (status, default "Todo"), Tags (multi_select)
//   Costs:   Title (title), Amount (number, EUR), Tags (multi_select)
// ============================================================
import { Client } from '@notionhq/client';

const notion = new Client({ auth: process.env.NOTION_TOKEN });

const DB = {
    note: process.env.NOTION_DB_MEMORY,
    task: process.env.NOTION_DB_TASKS,
    cost: process.env.NOTION_DB_COSTS
};

function tagList(tags = []) {
    return tags.slice(0, 5).map(t => ({ name: String(t).toLowerCase().slice(0, 40) }));
}
function rich(text) {
    return [{ type: 'text', text: { content: String(text ?? '').slice(0, 1900) } }];
}
function title(text) {
    return [{ type: 'text', text: { content: String(text ?? 'Untitled').slice(0, 200) } }];
}

export async function saveToNotion(entry) {
    const dbId = DB[entry.type];
    if (!dbId) throw new Error(`kein DB-Mapping fuer type=${entry.type}`);

    const props = {
        Title: { title: title(entry.title) },
        Tags:  { multi_select: tagList(entry.tags) }
    };

    if (entry.type === 'note') {
        props.Content = { rich_text: rich(entry.content) };
    }
    if (entry.type === 'task') {
        props.Status = { status: { name: 'Todo' } };
    }
    if (entry.type === 'cost') {
        props.Amount = { number: Number(entry.amount ?? 0) };
    }

    const page = await notion.pages.create({
        parent:     { database_id: dbId },
        properties: props,
        children:   entry.content ? [{
            object: 'block', type: 'paragraph',
            paragraph: { rich_text: rich(entry.content) }
        }] : []
    });

    return page.url;
}
