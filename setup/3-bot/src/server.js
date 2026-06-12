// HTTP server: /healthz + /mail (HMAC, rate-limit, raw body).
import http   from 'node:http';
import crypto from 'node:crypto';
import { config } from './config.js';

const buckets = new Map();
function rateLimitOk(ip) {
    const now = Date.now();
    const win = 60_000;
    const max = 10;
    const b = buckets.get(ip) || { ts: [] };
    b.ts = b.ts.filter(t => now - t < win);
    if (b.ts.length >= max) return false;
    b.ts.push(now);
    buckets.set(ip, b);
    return true;
}

function readBody(req, max) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        let len = 0;
        req.on('data', c => {
            len += c.length;
            if (len > max) { reject(new Error('too large')); req.destroy(); return; }
            chunks.push(c);
        });
        req.on('end',   () => resolve(Buffer.concat(chunks)));
        req.on('error', reject);
    });
}

function hmacOk(secret, body, header) {
    if (!header || typeof header !== 'string' || !header.startsWith('sha256=')) return false;
    const got = header.slice(7);
    const exp = crypto.createHmac('sha256', secret).update(body).digest('hex');
    if (got.length !== exp.length) return false;
    try { return crypto.timingSafeEqual(Buffer.from(got, 'hex'), Buffer.from(exp, 'hex')); }
    catch { return false; }
}

const START = Date.now();

export function startServer({ onMail, version = 'dev' } = {}) {
    const server = http.createServer(async (req, res) => {
        try {
            if (req.method === 'GET' && req.url === '/healthz') {
                res.writeHead(200, { 'content-type': 'application/json' });
                res.end(JSON.stringify({
                    ok: true,
                    uptime: Math.floor((Date.now() - START) / 1000),
                    version,
                }));
                return;
            }

            if (req.method === 'POST' && req.url === '/mail') {
                if (!config.web.secret) { res.writeHead(503).end('webhook disabled'); return; }
                const ip = req.socket.remoteAddress || 'unknown';
                if (!rateLimitOk(ip)) { res.writeHead(429).end('rate limit'); return; }
                let body;
                try { body = await readBody(req, 256 * 1024); }
                catch { res.writeHead(413).end('too large'); return; }

                const sig = req.headers['x-webhook-signature'];
                if (!hmacOk(config.web.secret, body, sig)) { res.writeHead(401).end('bad signature'); return; }

                let payload;
                try { payload = JSON.parse(body.toString('utf8')); }
                catch { res.writeHead(400).end('bad json'); return; }

                res.writeHead(202).end('accepted');
                Promise.resolve()
                    .then(() => onMail && onMail(payload))
                    .catch(e => console.error('[mail-pipeline]', e?.message || e));
                return;
            }

            res.writeHead(404).end();
        } catch (e) {
            console.error('[server]', e);
            try { res.writeHead(500).end(); } catch {}
        }
    });

    return new Promise(resolve => {
        server.listen(config.web.port, '0.0.0.0', () => {
            console.log(`[server] up. port=${config.web.port}`);
            resolve(server);
        });
    });
}
