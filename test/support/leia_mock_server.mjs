// Offline native-client integration fixture. No external request can leave this
// process: the production server's provider transport is replaced explicitly.
import assert from 'node:assert/strict';
import { createApp } from '../../server/server.mjs';
import { BudgetLedger } from '../../server/budget.mjs';

const accessToken = 'offline-fixture-token-at-least-32-characters';
const budget = new BudgetLedger({ path: null, ceilingUsd: 2 });
const provider = async (url, options) => {
  assert.equal(url, 'https://api.openai.com/v1/responses');
  const payload = JSON.parse(options.body);
  assert.equal(payload.store, false);
  const input = JSON.parse(payload.input[0].content);
  assert.equal(input.context.settings, undefined);
  if (input.message === 'Проверь ошибку сервера') {
    return { ok: false, status: 429 };
  }
  const previous = input.context.missions.filter((entry) => entry.outcome).at(-1);
  const isFollowup = Boolean(previous);
  const goal = input.context.goal;
  const noReply = previous?.outcome.kind === 'noReply';
  const contact = goal.context.includes('Ирина');
  const title = isFollowup
    ? noReply ? 'Проверь текст без повторного приглашения' : 'Попробуй рисунок с одной точкой схода'
    : contact ? 'Пригласи Ирину на короткую прогулку' : 'Нарисуй улицу по готовой схеме';
  const draft = contact && !isFollowup
    ? 'Ирина, привет! Хочешь прогуляться вместе в парке? Скажи, когда тебе удобно.'
    : noReply
      ? 'Задача на 3 минуты: прочитай приглашение. Оно короткое, предлагает конкретный формат и оставляет возможность выбрать время. Пока не отправляй его повторно.'
      : 'Поставь точку схода на линии горизонта. Проведи к ней две линии дороги. Добавь по прямоугольному дому с каждой стороны. Вертикали оставь вертикальными. Сравни рисунок с этим описанием.';
  const quote = isFollowup ? previous.outcome.facts : goal.context;
  const answer = {
    quickReplies: [],
    reply: isFollowup ? 'Учла результат и подготовила следующий небольшой шаг.' : 'Подготовка готова. Проверь материал и сделай одно действие.',
    goal: { id: goal.id, title: goal.title, context: goal.context, createdAt: goal.createdAt },
    mission: {
      id: '', goalId: goal.id, title,
      why: isFollowup ? noReply ? 'Ответа пока нет; повторять приглашение сразу нет оснований.' : 'Первая попытка показала, что полезно упростить построение перспективы.' : 'Можно начать с указанными временем и материалами.',
      minutes: isFollowup ? 3 : 5,
      oneAction: contact && !isFollowup ? 'Проверь подготовленный текст и отправь Ирине.' : 'Выполни короткое упражнение из подготовленного материала.',
      lightAction: 'Прочитай подготовленный материал без выполнения.',
      steps: [{ id: '', title: 'Прочитать материал', hint: 'Можно исправить его перед действием.' }],
      materials: [{ id: '', label: 'Готовый материал', text: draft, kind: contact && !isFollowup ? 'message' : 'draft' }],
      status: 'prepared', chapter: 'Первый опыт', ability: contact ? 'Ясная коммуникация' : 'Наблюдение',
      evidence: [{ quote }], contactNames: contact && !isFollowup ? ['Ирина'] : [],
    },
    understanding: goal.context, assumptions: [], needsClarification: false,
    nextDirection: 'Следующий ход зависит от фактического результата.',
    reflection: isFollowup ? {
      whatHappened: previous.outcome.facts,
      learned: noReply ? 'Доступность собеседника пока неизвестна.' : 'Построение перспективы пока вызывает трудность.',
      goalImpact: noReply ? 'Разговор пока не состоялся.' : 'Есть первая попытка рисунка и конкретная трудность.',
      nextMove: noReply ? 'Дать приглашению время и сделать независимый шаг.' : 'Упростить рисунок до одной точки схода.',
      realChange: !noReply,
    } : null,
    contextUpdates: [],
  };
  return { ok: true, status: 200, json: async () => ({
    status: 'completed', usage: { input_tokens: 1200, output_tokens: 400 },
    output: [{ type: 'message', content: [{ type: 'output_text', text: JSON.stringify(answer) }] }],
  }) };
};
const app = createApp({
  config: { apiKey: 'offline-fixture-not-a-real-key', accessToken, budgetUsd: 2,
    model: 'gpt-4.1-mini-2025-04-14', maxOutputTokens: 2800, requestsPerMinute: 60 },
  ledger: budget, fetchImpl: provider,
});
app.listen(0, '127.0.0.1', () => {
  console.log(JSON.stringify({ port: app.address().port, accessToken }));
});
const close = () => { app.closeAllConnections(); app.close(() => { budget.close(); process.exit(0); }); };
process.on('SIGTERM', close);
process.on('SIGINT', close);
