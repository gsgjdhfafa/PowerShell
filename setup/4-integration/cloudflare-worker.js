// Cloudflare Email Worker. Empfaengt Mails an inbox@deine-domain,
// signiert das JSON-Payload (HMAC-SHA256) und POSTet an den Bot.
//
// Setup (lokal):
//   npm i -g wrangler
//   wrangler init zf-mail   # diesen Code in src/worker.js einfuegen
//   wrangler secret put WEBHOOK_SECRET   # gleicher Wert wie Bot .env
//   wrangler secret put BOT_URL          # z.B. https://bot.deine-domain
//   wrangler deploy
// Dann im CF Dashboard -> Email Routing -> Rule "inbox@..." -> Action "Send to Worker".

import PostalMime from 'postal-mime';

export default {
  async email(message, env) {
    const buf    = await new Response(message.raw).arrayBuffer();
    const parsed = await new PostalMime().parse(buf);

    const payload = {
      from:    parsed.from?.address || message.from || '',
      to:      message.to            || '',
      subject: parsed.subject        || '',
      text:    parsed.text           || '',
    };

    const body = JSON.stringify(payload);
    const sig  = await hmac(env.WEBHOOK_SECRET, body);

    const r = await fetch(env.BOT_URL.replace(/\/+$/, '') + '/mail', {
      method: 'POST',
      headers: {
        'content-type':        'application/json',
        'x-webhook-signature': 'sha256=' + sig,
      },
      body,
    });
    if (!r.ok) message.setReject('downstream ' + r.status);
  },
};

async function hmac(secret, data) {
  const k = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const s = await crypto.subtle.sign('HMAC', k, new TextEncoder().encode(data));
  return [...new Uint8Array(s)].map(b => b.toString(16).padStart(2, '0')).join('');
}
