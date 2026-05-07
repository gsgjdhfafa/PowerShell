// CF Email Worker Payload -> {from,to,subject,text} und Classifier-Input bauen.

function stripHtml(html) {
    return String(html || '')
        .replace(/<style[\s\S]*?<\/style>/gi, ' ')
        .replace(/<script[\s\S]*?<\/script>/gi, ' ')
        .replace(/<[^>]+>/g, ' ')
        .replace(/&nbsp;/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

export function parseWorkerPayload(p) {
    const text = String(p?.text || '').trim();
    return {
        from:    String(p?.from || '').trim(),
        to:      String(p?.to   || '').trim(),
        subject: String(p?.subject || '').trim(),
        text:    text || stripHtml(p?.html),
    };
}

export function buildMailText({ from, subject, text }) {
    const fromDomain = (from.split('@')[1] || from).slice(0, 64);
    const subj = subject.slice(0, 200);
    const body = (text || '').slice(0, 8000);
    return `Mail von ${fromDomain}\nSubject: ${subj}\n\n${body}`.trim();
}
