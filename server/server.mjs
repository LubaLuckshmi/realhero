import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { BudgetLedger, MODEL_RATES } from './budget.mjs';
import { createGateway } from './gateway.mjs';
import { PublicError, publicError } from './errors.mjs';

const MAX_BODY_BYTES = 130_000;

export function configFromEnv(env = process.env) {
  const number = (key, fallback, min, max) => {
    const value = env[key] === undefined || env[key] === '' ? fallback : Number(env[key]);
    if (!Number.isFinite(value) || value < min || value > max) throw new Error(`Invalid ${key}`);
    return value;
  };
  const config = {
    apiKey: env.OPENAI_API_KEY || '',
    accessToken: env.REALHERO_ACCESS_TOKEN || '',
    budgetUsd: number('REALHERO_TEST_BUDGET_USD', 0, 0, 20),
    model: env.REALHERO_MODEL || 'gpt-4.1-mini-2025-04-14',
    maxOutputTokens: number('REALHERO_MAX_OUTPUT_TOKENS', 2800, 512, 4096),
    requestsPerMinute: number('REALHERO_REQUESTS_PER_MINUTE', 10, 1, 60),
    host: env.REALHERO_HOST || '127.0.0.1',
    port: number('REALHERO_PORT', 8787, 0, 65535),
    ledgerPath: env.REALHERO_LEDGER_PATH || './data/usage.json',
  };
  if (config.accessToken.length < 32) throw new Error('REALHERO_ACCESS_TOKEN must have at least 32 random characters.');
  if (!Object.hasOwn(MODEL_RATES, config.model)) throw new Error('Unsupported REALHERO_MODEL budget rates.');
  return config;
}

function authorized(req, accessToken) {
  const provided = req.headers.authorization ?? '';
  const expected = `Bearer ${accessToken}`;
  const digest = (value) => createHash('sha256').update(value).digest();
  return timingSafeEqual(digest(provided), digest(expected));
}

function send(res, status, value) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  res.end(JSON.stringify(value));
}

async function readJson(req) {
  if (!/^application\/json(?:;|$)/i.test(req.headers['content-type'] ?? '')) {
    throw new PublicError(415, 'content_type', 'Сервер принимает только JSON.');
  }
  if (Number(req.headers['content-length'] ?? 0) > MAX_BODY_BYTES) {
    req.resume();
    throw new PublicError(413, 'body_too_large', 'Сообщение слишком большое.');
  }
  const chunks = []; let bytes = 0;
  for await (const chunk of req) {
    bytes += chunk.length;
    if (bytes > MAX_BODY_BYTES) throw new PublicError(413, 'body_too_large', 'Сообщение слишком большое.');
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw new PublicError(400, 'invalid_json', 'Не удалось прочитать сообщение.'); }
}

export function createApp({ config, ledger, fetchImpl = fetch, clock = () => new Date() }) {
  const gateway = createGateway({ config, ledger, fetchImpl, clock });
  const rateWindows = new Map();
  let inFlight = 0;
  const server = createServer(async (req, res) => {
    try {
      if (req.method === 'GET' && req.url === '/health') {
        send(res, 200, { service: 'realhero-leia', version: 1, status: 'ok',
          liveEnabled: config.budgetUsd > 0 && Boolean(config.apiKey) });
        return;
      }
      if (req.method !== 'POST' || req.url !== '/v1/leia') {
        throw new PublicError(404, 'not_found', 'Такого действия нет.');
      }
      if (!authorized(req, config.accessToken)) {
        req.resume(); throw new PublicError(401, 'unauthorized', 'Проверьте токен подключения в настройках.');
      }
      const now = Date.now(); const address = req.socket.remoteAddress ?? 'local';
      for (const [key, window] of rateWindows) if (now - window.start >= 60_000) rateWindows.delete(key);
      const window = rateWindows.get(address) ?? { start: now, requests: 0 };
      window.requests += 1; rateWindows.set(address, window);
      if (window.requests > config.requestsPerMinute || rateWindows.size > 1024) {
        throw new PublicError(429, 'rate_limited', 'Слишком много запросов. Повторите через минуту.');
      }
      if (inFlight >= 2) throw new PublicError(429, 'busy', 'Лея уже готовит ответ. Подождите немного.');
      inFlight += 1;
      try {
        const body = await readJson(req);
        const answer = await gateway(body);
        send(res, 200, answer);
      } finally { inFlight -= 1; }
    } catch (error) {
      const safe = publicError(error);
      send(res, safe.status, { error: { code: safe.code, message: safe.message } });
    }
  });
  server.requestTimeout = 12_000;
  server.headersTimeout = 10_000;
  server.keepAliveTimeout = 5000;
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  let ledger;
  try {
    const config = configFromEnv();
    ledger = new BudgetLedger({ path: config.ledgerPath, ceilingUsd: config.budgetUsd });
    const server = createApp({ config, ledger });
    server.listen(config.port, config.host, () => {
      console.log(`RealHero server listening on ${config.host}:${config.port}; paid API ${config.budgetUsd > 0 ? 'budget enabled' : 'disabled'}.`);
    });
    const close = () => { server.close(() => { ledger.close(); process.exit(0); }); };
    process.on('SIGINT', close); process.on('SIGTERM', close);
    server.on('error', () => { ledger.close(); console.error('Server could not start. Check host and port.'); process.exit(1); });
  } catch (error) {
    ledger?.close();
    // Config errors contain only variable names, no values.
    console.error(error.message); process.exit(1);
  }
}

