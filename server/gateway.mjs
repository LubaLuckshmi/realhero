import { randomUUID } from 'node:crypto';
import { LEIA_SCHEMA, conforms, projectSchema } from './schema.mjs';
import { LEIA_INSTRUCTIONS, modelContext, trustedSources } from './prompt.mjs';
import { PROJECT_INSTRUCTIONS, wantsSearch, referencesFrom } from './project.mjs';
import { PublicError } from './errors.mjs';
import { conservativeCost, usageCost } from './budget.mjs';

const OPERATIONS = new Set(['plan', 'onboard', 'mission', 'adapt', 'chat', 'result']);
const nonempty = (value) => typeof value === 'string' && value.trim().length > 0;

export function validateRequest(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body) || !OPERATIONS.has(body.operation)
    || typeof body.message !== 'string' || body.message.length > 8000
    || (body.context != null && (typeof body.context !== 'object' || Array.isArray(body.context)))) {
    throw new PublicError(400, 'invalid_request', 'Нужны операция, текст сообщения и контекст цели.');
  }
  if (body.version != null && ![1, 2].includes(body.version)) {
    throw new PublicError(400, 'unsupported_version', 'Обновите приложение для подключения к Лее.');
  }
  if (!trustedSources(body).length) {
    throw new PublicError(400, 'missing_context', 'Расскажите своими словами, чего хотите и что уже происходит.');
  }
}

export function validateGrounding(data, body) {
  const sources = trustedSources(body);
  const contained = (quote) => nonempty(quote) && sources.some((source) => source.includes(quote.trim()));
  if (data.contextUpdates.some((fact) => !contained(fact.sourceQuote))) {
    throw new PublicError(502, 'ungrounded_response', 'Лея не смогла подтвердить основание ответа. Попробуйте ещё раз.');
  }
  if (data.needsClarification && data.mission !== null) {
    throw new PublicError(502, 'invalid_ai_response', 'Ответ Леи требует уточнения. Попробуйте ещё раз.');
  }
  const mission = data.mission;
  if (!mission) return;
  const answers = body.context?.discovery?.answers;
  if (body.operation === 'onboard' && answers &&
      ['energy', 'time', 'people'].every((key) => ['yes', 'no', 'unsure'].includes(answers[key]))) {
    const ceiling = answers.energy === 'yes' && answers.time === 'yes' ? 5 : 2;
    if (mission.minutes > ceiling || (answers.people === 'no' && mission.contactNames.length > 0)) {
      throw new PublicError(502, 'overloaded_mission', 'Этот шаг получился тяжелее выбранного. Попроси Лею упростить его.');
    }
  }
  if (!nonempty(mission.title) || !nonempty(mission.oneAction) || !nonempty(mission.why)
    || mission.materials.some((material) => !nonempty(material.text) || !nonempty(material.label))
    || mission.steps.some((step) => !nonempty(step.title))
    || mission.materials.some((material) => /\[(?:имя|ссылка|текст|подстав|придум|встав|дополни)/iu.test(material.text))) {
    throw new PublicError(502, 'unprepared_response', 'Лея не закончила подготовку материалов. Попробуйте ещё раз.');
  }
  if (mission.evidence.some((fact) => !contained(fact.quote))
    || mission.contactNames.some((name) => !contained(name))) {
    throw new PublicError(502, 'ungrounded_response', 'Лея не смогла подтвердить факты миссии. Попробуйте ещё раз.');
  }
}

export function createGateway({ config, ledger, fetchImpl = fetch, clock = () => new Date() }) {
  return async (body) => {
    validateRequest(body);
    if (!(config.budgetUsd > 0)) {
      throw new PublicError(503, 'budget_not_approved', 'Платные запросы пока выключены. Тестовый бюджет ещё не согласован.');
    }
    if (!config.apiKey) {
      throw new PublicError(503, 'ai_not_configured', 'Сервер Леи ещё не подключён к OpenAI. Ваш контекст сохранён.');
    }
    const search = wantsSearch(body);
    const schema = body.version === 2 ? projectSchema(body.operation) : LEIA_SCHEMA;
    const payload = {
      model: config.model,
      instructions: body.version === 2 ? PROJECT_INSTRUCTIONS : LEIA_INSTRUCTIONS,
      input: [{ role: 'user', content: JSON.stringify({...modelContext(body), searchRequested: search}) }],
      text: { format: { type: 'json_schema', name: 'realhero_leia_v1', strict: true, schema } },
      max_output_tokens: config.maxOutputTokens,
      store: false,
      ...(search ? {tools: [{type: 'web_search', search_content_types: ['image', 'text'],
        image_settings: {max_results: 4, caption: true}, search_context_size: 'low'}],
        tool_choice: 'required', max_tool_calls: 1,
        include: ['web_search_call.action.sources', 'web_search_call.results']} : {}),
    };
    if (Buffer.byteLength(JSON.stringify(payload), 'utf8') > 130_000) {
      throw new PublicError(413, 'context_too_large', 'Контекст слишком большой. Сократите длинные материалы и повторите.');
    }
    const reservation = ledger.reserve(conservativeCost(payload, config.model, config.maxOutputTokens) + (search ? 0.05 : 0));
    let response;
    try {
      // One bounded search at most. No automatic retries or person-directed actions.
      response = await fetchImpl('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${config.apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(payload), signal: AbortSignal.timeout(search ? 55_000 : 35_000),
      });
    } catch {
      // Ambiguous requests can have been billed. Retain the full reservation.
      throw new PublicError(502, 'ai_unreachable', 'Сервер не получил ответ Леи. Ничего не отправлено внешним людям; попробуйте ещё раз.');
    }
    if (!response.ok) {
      // Never forward provider error bodies, headers, keys or user data.
      const code = response.status === 429 ? 'provider_limit' : 'provider_error';
      throw new PublicError(502, code, response.status === 429
        ? 'OpenAI временно ограничил запросы. Подождите и повторите.'
        : 'OpenAI не принял запрос. Проверьте серверное подключение.');
    }
    let raw;
    try { raw = await response.json(); }
    catch { throw new PublicError(502, 'invalid_ai_response', 'Лея вернула неполный ответ. Попробуйте ещё раз.'); }
    const cost = usageCost(raw.usage, config.model);
    if (cost !== null) ledger.settle(reservation, cost + (search ? 0.05 : 0));
    // Keep a conservative $0.05 search charge in the existing cumulative ledger:
    // tool fees + extra search input. Never refund unknown/ambiguous usage.
    if (raw.status !== 'completed') {
      throw new PublicError(502, 'incomplete_ai_response', 'Лея не закончила подготовку. Повторите запрос.');
    }
    const content = (raw.output ?? []).flatMap((entry) => entry.content ?? []);
    if (content.some((entry) => entry.type === 'refusal')) {
      throw new PublicError(422, 'ai_refused', 'Лея не может подготовить это действие. Уточните цель или выберите другой ход.');
    }
    const text = content.filter((entry) => entry.type === 'output_text').map((entry) => entry.text).join('');
    let data;
    try { data = JSON.parse(text); }
    catch { throw new PublicError(502, 'invalid_ai_response', 'Ответ Леи не удалось прочитать. Попробуйте ещё раз.'); }
    if (!conforms(data, schema)) {
      throw new PublicError(502, 'invalid_ai_response', 'Ответ Леи не прошёл проверку. Попробуйте ещё раз.');
    }
    validateGrounding(data, body);
    if (body.version === 2) {
      data.sources = referencesFrom(raw);
      data.searchPerformed = search && (raw.output ?? []).some((e) => e.type === 'web_search_call' && e.status === 'completed');
      if (search && (!data.searchPerformed || !data.sources.length)) {
        throw new PublicError(502, 'search_empty', 'Поиск не вернул проверяемых примеров. Уточни запрос и повтори; описание темы не подставлялось вместо поиска.');
      }
    }
    if (data.goal) {
      const previousId = body.context?.goal?.id;
      data.goal.id = previousId || randomUUID();
      data.goal.createdAt = body.context?.goal?.createdAt || clock().toISOString();
      // Keep original human context. AI's own summary must never become a new source of facts.
      data.goal.context = typeof body.context?.goal?.context === 'string'
        ? body.context.goal.context : body.message;
    }
    if (data.mission) {
      data.mission.id = randomUUID();
      data.mission.goalId = body.context?.goal?.id || data.goal?.id || randomUUID();
      data.mission.steps.forEach((step, index) => { step.id = `step-${index + 1}`; });
      data.mission.materials.forEach((material, index) => { material.id = `material-${index + 1}`; });
    }
    return data;
  };
}

