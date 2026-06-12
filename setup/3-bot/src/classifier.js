// Klassifiziert eingehenden Text und routet durch die Pipeline.
import { aiClassify } from './ai.js';
import * as pipeline  from './pipeline.js';

export async function classifyAndProcess(text) {
    const cls = await aiClassify(text);
    const r   = await pipeline.process(cls.kind, text);
    return { ...r, confidence: cls.confidence };
}
