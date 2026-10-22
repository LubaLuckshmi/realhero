import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { BudgetLedger, conservativeCost } from '../budget.mjs';
import { createApp, configFromEnv } from '../server.mjs';
import { createGateway } from '../gateway.mjs';
import { trustedSources } from '../prompt.mjs';
import { LEIA_SCHEMA } from '../schema.mjs';

const token = 'test-access-token-32-characters-or-more';
const config = (overrides = {}) => ({
  apiKey: 'test-only-not-a-real-key', accessToken: token, budgetUsd: 2,
  model: 'gpt-4.1-mini-2025-04-14', maxOutputTokens: 2800,
  requestsPerMinute: 60, ...overrides,
});
const request = (overrides = {}) => ({
  version: 1, operation: 'plan',
  message: 'Хочу проверить прототип. Андрей раньше просил показать его. Два экрана готовы. Есть 15 минут.',
  context: { goal: { id: 'goal-1', title: 'Проверить прототип', context: 'Два экрана готовы.', createdAt: '2026-10-14T07:00:00Z' }, chat: [] },
  ...overrides,
});
const answer = () => ({
  quickReplies: [],
  reply: 'Приглашение и три вопроса готовы. Проверьте текст и отправьте Андрею.',
  goal: { id: '', title: 'Проверить прототип', context: 'Два экрана готовы.', createdAt: '' },
  mission: {
    id: '', goalId: '', title: 'Пригласи Андрея на демо', why: 'Андрей уже интересовался прототипом.',
    minutes: 10, oneAction: 'Проверьте готовое приглашение и отправьте Андрею.',
    lightAction: 'Отправьте только короткое приглашение.',
    steps: [{ id: '', title: 'Проверьте приглашение', hint: 'При необходимости измените текст.' },
      { id: '', title: 'Отправьте текст', hint: 'Откройте привычный мессенджер.' }],
    materials: [
      { id: '', label: 'Приглашение', kind: 'message', text: 'Андрей, привет! Два экрана прототипа готовы. Можешь посмотреть и дать обратную связь?' },
      { id: '', label: 'Три вопроса', kind: 'questions', text: 'Что понятно сразу?\nЧто мешает начать?\nЧто стоит проверить дальше?' },
    ],
    status: 'prepared', chapter: 'Первая обратная связь', ability: 'Ясная коммуникация',
    evidence: [{ quote: 'Андрей раньше просил показать его.' }], contactNames: ['Андрей'],
  },
  understanding: 'Готовый прототип нужно показать уже заинтересованному человеку.',
  assumptions: [], needsClarification: false, nextDirection: 'Использовать фактический ответ для следующего шага.',
  reflection: null, contextUpdates: [{ text: 'Два экрана готовы.', sourceQuote: 'Два экрана готовы.' }],
});
const provider = (data, overrides = {}) => ({
  status: 'completed', usage: { input_tokens: 2000, output_tokens: 400 },
  output: [{ type: 'message', content: [{ type: 'output_text', text: JSON.stringify(data) }] }],
  ...overrides,
});
const mockProvider = (data, observer = () => {}) => async (url, options) => {
  observer(url, options); return { ok: true, status: 200, json: async () => provider(data) };
};
const ledger = (ceilingUsd = 2) => new BudgetLedger({ path: null, ceilingUsd });

async function withServer(t, overrides = {}, fetchImpl = mockProvider(answer()), imageReader = async () => {throw Error('No image fixture');}) {
  const appConfig = config(overrides);
  const budget = ledger(appConfig.budgetUsd);
  const server = createApp({ config: appConfig, ledger: budget, fetchImpl, imageReader });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => { server.closeAllConnections(); server.close(resolve); budget.close(); }));
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (body = request(), headers = {}) => fetch(`${base}/v1/leia`, {
    method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  return { base, post, budget };
}

test('health reports a running server without enabling paid AI; unauthorized requests never call provider', async (t) => {
  let calls = 0;
  const app = await withServer(t, { budgetUsd: 0 }, async () => { calls++; throw Error('must not call'); });
  assert.deepEqual(await (await fetch(`${app.base}/health`)).json(),
    { service: 'realhero-leia', version: 1, status: 'ok', liveEnabled: false });
  const response = await app.post(request(), { authorization: 'Bearer incorrect' });
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'unauthorized');
  assert.equal(calls, 0);
});

test('unapproved budget denies every personal AI request, even when a key is configured', async (t) => {
  let calls = 0;
  const app = await withServer(t, { budgetUsd: 0 }, async () => { calls++; throw Error('must not call'); });
  const response = await app.post();
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'budget_not_approved');
  assert.equal(calls, 0);
});

test('mocked real-provider flow uses Responses strict schema, server secret only, grounded prepared materials', async (t) => {
  let payload;
  const app = await withServer(t, {}, mockProvider(answer(), (url, options) => {
    assert.equal(url, 'https://api.openai.com/v1/responses');
    assert.equal(options.headers.Authorization, 'Bearer test-only-not-a-real-key');
    payload = JSON.parse(options.body);
  }));
  const body = request(); body.context.settings = { serverToken: 'never-forward-this-secret', apiKey: 'never-forward-key' };
  const response = await app.post(body);
  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.mission.goalId, 'goal-1');
  assert.equal(data.goal.id, 'goal-1');
  assert.equal(data.goal.context, body.context.goal.context);
  assert.equal(data.mission.status, 'prepared');
  assert.ok(data.mission.id);
  assert.equal(data.mission.materials[0].id, 'material-1');
  assert.equal(payload.store, false);
  assert.equal(payload.max_output_tokens, 2800);
  assert.equal(payload.text.format.strict, true);
  assert.deepEqual(payload.text.format.schema, LEIA_SCHEMA);
  assert.equal(payload.tools, undefined);
  assert.ok(!payload.input[0].content.includes('never-forward'));
  assert.ok(!JSON.stringify(data).includes('test-only-not-a-real-key'));
  assert.ok(app.budget.state.spentUsd > 0);
  assert.ok(app.budget.state.spentUsd < 0.01);
});

test('fabricated contact is rejected and no mission is returned', async (t) => {
  const data = answer(); data.mission.contactNames = ['Виктор'];
  const app = await withServer(t, {}, mockProvider(data));
  const response = await app.post();
  assert.equal(response.status, 502);
  const result = await response.json();
  assert.equal(result.error.code, 'ungrounded_response');
  assert.equal(result.mission, undefined);
});

test('AI drafts cannot become evidence; unsupported fact extraction is rejected', async (t) => {
  const data = answer(); data.contextUpdates[0].sourceQuote = 'Андрей согласился на завтра';
  const body = request();
  body.context.chat = [{ role: 'assistant', text: 'Андрей согласился на завтра' }];
  body.context.missions = [{ title: 'Андрей согласился на завтра', materials: [{ text: 'Андрей согласился на завтра' }] }];
  assert.ok(!trustedSources(body).includes('Андрей согласился на завтра'));
  const app = await withServer(t, {}, mockProvider(data));
  const response = await app.post(body);
  assert.equal((await response.json()).error.code, 'ungrounded_response');
});

test('AI goal summary is not promoted to trusted human context', async () => {
  const data = answer(); data.goal.context = 'Виктор договорился на завтра';
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  const result = await gateway(request());
  assert.equal(result.goal.context, 'Два экрана готовы.');
  const body = request(); body.context.goal.title = 'Виктор договорился на завтра';
  assert.ok(!trustedSources(body).includes('Виктор договорился на завтра'));
});

test('provider failures are redacted; no simulated success fallback', async (t) => {
  const app = await withServer(t, {}, async () => {
    throw Error('test-only-not-a-real-key and private user context');
  });
  const response = await app.post();
  assert.equal(response.status, 502);
  const text = await response.text();
  assert.ok(!text.includes('test-only'));
  assert.ok(!text.includes('private user'));
  assert.equal(JSON.parse(text).error.code, 'ai_unreachable');
  assert.ok(app.budget.state.spentUsd > 0, 'retain conservative reservation after ambiguous failure');
});

test('incomplete output and model refusal are explicit errors, never fake completion', async () => {
  for (const [raw, expected] of [
    [provider(answer(), { status: 'incomplete', incomplete_details: { reason: 'max_output_tokens' } }), 'incomplete_ai_response'],
    [provider(answer(), { output: [{ content: [{ type: 'refusal', refusal: 'private policy detail' }] }] }), 'ai_refused'],
  ]) {
    const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: async () => ({ ok: true, json: async () => raw }) });
    await assert.rejects(gateway(request()), (error) => error.code === expected);
  }
});

test('unfinished placeholder materials and schema-invalid response are rejected', async () => {
  const cases = [answer(), answer()];
  cases[0].mission.materials[0].text = 'Привет, [имя]! Посмотри [ссылка]';
  cases[1].mission.minutes = '15';
  for (let index = 0; index < cases.length; index++) {
    const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(cases[index]) });
    await assert.rejects(gateway(request()), (error) => error.code === (index === 0 ? 'unprepared_response' : 'invalid_ai_response'));
  }
});

test('onboarding can ask one necessary clarification instead of inventing an action', async () => {
  const data = answer();
  data.mission = null; data.goal = null; data.contextUpdates = [];
  data.needsClarification = true; data.reply = 'Какой навык хотите освоить и для чего он нужен?';
  data.quickReplies = ['Рисование', 'Язык', 'Не знаю'];
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  const result = await gateway(request({ operation: 'onboard', message: 'Хочу научиться чему-нибудь новому', context: {} }));
  assert.equal(result.mission, null); assert.equal(result.needsClarification, true);
  assert.deepEqual(result.quickReplies, ['Рисование', 'Язык', 'Не знаю']);
});

test('short discovery refuses an action above the selected energy/time load', async () => {
  const body = request({ operation: 'onboard' });
  body.context.discovery = { answers: { energy: 'no', time: 'unsure', people: 'yes' } };
  const data = answer();
  data.mission.minutes = 5;
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  await assert.rejects(gateway(body), (error) => error.code === 'overloaded_mission');
  data.mission.minutes = 2;
  const lighter = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  assert.equal((await lighter(body)).mission.minutes, 2);
});

test('discovery preserves refusal of social contact without treating it as a permanent label', async () => {
  const body = request({ operation: 'onboard' });
  body.context.discovery = { answers: { energy: 'yes', time: 'yes', people: 'no' } };
  const data = answer();
  data.mission.minutes = 2;
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  await assert.rejects(gateway(body), (error) => error.code === 'overloaded_mission');
  body.operation = 'mission';
  assert.equal((await gateway(body)).mission.contactNames[0], 'Андрей');
});

test('structured clarification rejects an overflowing answer wall and oversized quick replies', async () => {
  const data = answer();
  data.reply = 'А'.repeat(421);
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data) });
  await assert.rejects(gateway(request()), (error) => error.code === 'invalid_ai_response');
  data.reply = 'Один вопрос.';
  data.quickReplies = ['А'.repeat(49)];
  await assert.rejects(gateway(request()), (error) => error.code === 'invalid_ai_response');
});

test('refusal/no answer reaches adaptation in real context and is not marked a life victory', async () => {
  const body = request({ operation: 'result', message: 'Ответа от Андрея пока нет, приглашение отправлено вчера.' });
  body.context.missions = [{ result: { outcome: 'noResponse', note: 'Ответа пока нет.' } }];
  const data = answer(); data.mission = null; data.contextUpdates = [];
  data.reflection = { whatHappened: 'Ответа пока нет.', learned: 'Интерес и доступность ещё неизвестны.',
    goalImpact: 'Обратная связь пока не получена.', nextMove: 'Собрать критерии проверки независимо от ответа.', realChange: false };
  const gateway = createGateway({ config: config(), ledger: ledger(), fetchImpl: mockProvider(data, (_, options) => {
    const payload = JSON.parse(options.body);
    const input = JSON.parse(payload.input[0].content);
    assert.equal(input.operation, 'result');
    assert.ok(input.trustedSources.some((text) => text.includes('Ответа от Андрея пока нет')));
    assert.ok(payload.instructions.includes('НЕ предлагай снова немедленно писать'));
  }) });
  const result = await gateway(body);
  assert.equal(result.reflection.realChange, false);
  assert.ok(!JSON.stringify(result).includes('победа'));
});

test('rate limit and request validation run before provider dispatch', async (t) => {
  let calls = 0;
  const app = await withServer(t, { requestsPerMinute: 2, budgetUsd: 0 }, async () => { calls++; });
  const invalid = await app.post({ operation: 'plan', message: '' });
  assert.equal((await invalid.json()).error.code, 'missing_context');
  const second = await app.post(); assert.equal(second.status, 503);
  const third = await app.post(); assert.equal(third.status, 429);
  assert.equal((await third.json()).error.code, 'rate_limited');
  assert.equal(calls, 0);
});

test('body limits, content type and malformed JSON have useful errors', async (t) => {
  const app = await withServer(t, { budgetUsd: 0 });
  const oversized = await app.post(request({ message: 'x'.repeat(140_000) }));
  assert.equal(oversized.status, 413);
  const wrongType = await app.post(request(), { 'content-type': 'text/plain' });
  assert.equal(wrongType.status, 415);
  const malformed = await fetch(`${app.base}/v1/leia`, { method: 'POST', headers: {
    authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: '{' });
  assert.equal((await malformed.json()).error.code, 'invalid_json');
});

test('budget reservations survive restart and exhausted budget prevents API call', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'realhero-budget-')); const path = join(directory, 'usage.json');
  try {
    const first = new BudgetLedger({ path, ceilingUsd: 0.01 });
    first.reserve(0.009); first.close();
    const reopened = new BudgetLedger({ path, ceilingUsd: 0.01 });
    assert.equal(reopened.state.spentUsd, 0.009);
    assert.throws(() => reopened.reserve(0.002), (error) => error.code === 'budget_exhausted');
    assert.throws(() => new BudgetLedger({ path, ceilingUsd: 2 }), /locked/);
    const serialized = readFileSync(path, 'utf8');
    assert.ok(!serialized.includes('goal')); reopened.close();
    let calls = 0;
    const gateway = createGateway({ config: config({ budgetUsd: 0.00001 }), ledger: ledger(0.00001),
      fetchImpl: async () => { calls++; } });
    await assert.rejects(gateway(request()), (error) => error.code === 'budget_exhausted');
    assert.equal(calls, 0);
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test('corrupt usage ledger fails closed rather than resetting spending history', () => {
  const directory = mkdtempSync(join(tmpdir(), 'realhero-budget-')); const path = join(directory, 'usage.json');
  try {
    writeFileSync(path, 'not json');
    assert.throws(() => new BudgetLedger({ path, ceilingUsd: 2 }), /unreadable/);
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test('configuration defaults to disabled budget and rejects weak token/unknown cost model', () => {
  assert.equal(configFromEnv({ REALHERO_ACCESS_TOKEN: token }).budgetUsd, 0);
  assert.throws(() => configFromEnv({}), /ACCESS_TOKEN/);
  assert.throws(() => configFromEnv({ REALHERO_ACCESS_TOKEN: token, REALHERO_MODEL: 'unpriced-model' }), /MODEL/);
  assert.throws(() => configFromEnv({ REALHERO_ACCESS_TOKEN: token, REALHERO_TEST_BUDGET_USD: 'unbounded' }), /BUDGET/);
  assert.ok(conservativeCost({ message: 'Привет' }, 'gpt-4.1-mini', 2800) > 0);
});

test('unclear collection stays a question; prior AI craft instructions are not user evidence', async (t) => {
  const data = answer();
  Object.assign(data, { mission: null, goal: null, contextUpdates: [], assumptions: [],
    needsClarification: true, quickReplies: ['Своими руками', 'С мастерами', 'Пока не знаю'],
    understanding: 'Есть идея коллекции; способ создания пока не выбран.',
    reply: 'Хочешь делать игрушки своими руками или придумать коллекцию для изготовления с мастерами?',
    nextDirection: 'Уточнить способ создания.' });
  let sent;
  const app = await withServer(t, {}, mockProvider(data, (_, options) => { sent = JSON.parse(options.body); }));
  const body = request({message: 'Хочу создать коллекцию ёлочных игрушек', context: {
    chat: [{role: 'assistant', text: 'Возьми вату и клей, сделай шарик.'}],
    interaction: {guidance: 'Когда выбор сделан, подготовь одно действие до пяти минут.'},
    missions: [{title: 'Сделай шарик', materials: [{text: 'Возьми вату и клей'}]}]
  }});
  const response = await app.post(body);
  assert.equal(response.status, 200);
  const actual = await response.json();
  assert.equal(actual.mission, null);
  assert.equal(actual.needsClarification, true);
  assert.deepEqual(actual.quickReplies, data.quickReplies);
  assert.deepEqual(JSON.parse(sent.input[0].content).trustedSources, [body.message]);
  assert.match(sent.instructions, /ПРОВЕРКА ГОТОВНОСТИ ПЕРЕД МИССИЕЙ/);
  assert.match(sent.instructions, /один ответ не разрешает автоматически/);
});

test('unknown answer can remain clarification without inventing a mission', async (t) => {
  const data = answer();
  Object.assign(data, {mission: null, goal: null, contextUpdates: [], assumptions: [],
    needsClarification: true, reply: 'Что ближе: придумать внешний вид или попробовать изготовление?',
    quickReplies: ['Придумать внешний вид', 'Попробовать изготовление', 'Ни один'], nextDirection: 'Выбрать направление'});
  const app = await withServer(t, {}, mockProvider(data));
  const response = await app.post(request({message: 'Пока не знаю', context: {
    goal: {context: 'Хочу свою коллекцию ёлочных игрушек'},
    chat: [{role: 'user', text: 'Хочу свою коллекцию ёлочных игрушек'}]
  }}));
  assert.equal(response.status, 200);
  assert.equal((await response.json()).mission, null);
});

function projectAnswer() {
  return {...answer(),mission:null,goal:null,contextUpdates:[],needsClarification:false,
    reply:'Вот примеры для коллекции. Посмотри костюмы и оформление сцены.',
    workspace:{summary:'',roadmap:[],drafts:[]}};
}
test('project search returns actual provider references and images, bounds tools and accounts fees',async(t)=>{
  let payload;
  const app=await withServer(t,{},async(_,options)=>{
    payload=JSON.parse(options.body);
    return {ok:true,status:200,json:async()=>({...provider(projectAnswer()),output:[
      {type:'web_search_call',status:'completed',action:{sources:[{url:'https://theatre.example/production',title:'Постановка'}]},results:[
        {type:'image_result',source_website_url:'https://theatre.example/gallery',thumbnail_url:'https://images.example/costume.jpg',caption:'Костюм Щелкунчика'},
        {type:'image_result',source_website_url:'http://127.0.0.1/secret',image_url:'https://images.example/bad.jpg',caption:'Недоверенный'}]},
      ...provider(projectAnswer()).output,
    ]})};
  }, async url => ({url,type:'image/jpeg',body:Buffer.concat([Buffer.from([255,216,255]),Buffer.alloc(1100)])}));
  const response=await app.post(request({version:2,operation:'chat',message:'Поищи примеры по Щелкунчику в Петербурге'}));
  assert.equal(response.status,200);const data=await response.json();
  assert.equal(data.mission,null);assert.equal(data.searchPerformed,true);
  assert.equal(data.sources.length,2);assert.equal(data.sources[0].imageUrl,'https://images.example/costume.jpg');
  assert.equal(payload.max_tool_calls,1);assert.equal(payload.tool_choice,'required');
  assert.deepEqual(payload.tools[0].search_content_types,['image','text']);
  assert.ok(app.budget.state.spentUsd>=0.05);assert.ok(app.budget.state.spentUsd<0.06);
});
test('ordinary project chat has no search fee, no mission, and roadmap is only a proposal',async(t)=>{
  let payload;const data=projectAnswer();data.workspace.roadmap=[{id:'',title:'Собрать замысел',detail:'Выбрать тему'}];
  const app=await withServer(t,{},mockProvider(data,(_,options)=>payload=JSON.parse(options.body)));
  const response=await app.post(request({version:2,operation:'chat',message:'Предложи дорожную карту'}));
  assert.equal(response.status,200);const actual=await response.json();
  assert.equal(actual.mission,null);assert.deepEqual(actual.workspace.roadmap,data.workspace.roadmap);
  assert.equal(payload.tools,undefined);assert.equal(actual.searchPerformed,false);assert.deepEqual(actual.sources,[]);
});
test('project chat rejects a fabricated mission instead of assigning it',async(t)=>{
  const data=projectAnswer();data.mission=answer().mission;
  const app=await withServer(t,{},mockProvider(data));
  const response=await app.post(request({version:2,operation:'chat',message:'Расскажи о вариантах'}));
  assert.equal(response.status,502);assert.equal((await response.json()).error.code,'invalid_ai_response');
});
test('requested search without actual sources is an explicit failure, not a pretend result',async(t)=>{
  const app=await withServer(t,{},mockProvider(projectAnswer()));
  const response=await app.post(request({version:2,operation:'chat',message:'Найди примеры'}));
  assert.equal(response.status,502);assert.equal((await response.json()).error.code,'search_empty');
});
test('search ceiling reserves tool cost before dispatch and never resets existing cumulative spending',async(t)=>{
  let calls=0; const app=await withServer(t,{budgetUsd:0.04},async()=>{calls++;throw Error('forbidden');});
  const response=await app.post(request({version:2,operation:'chat',message:'Поищи примеры'}));
  assert.equal(response.status,429);assert.equal(calls,0);assert.equal(app.budget.state.spentUsd,0);
});
test('text-only provider result is enriched in the real HTTP gateway; user query is unchanged and model called once',async(t)=>{
  let paidCalls=0;
  const text='Поищи примеры костюмов Щелкунчика в Питере для моей коллекции';
  const app=await withServer(t,{},async(_,options)=>{
    paidCalls++;
    assert.equal(JSON.parse(JSON.parse(options.body).input[0].content).message,text);
    return {ok:true,json:async()=>provider(projectAnswer(),{output:[
      {type:'web_search_call',status:'completed',action:{sources:[1,2,3].map(n=>({url:`https://theatre.example/${n}`,title:`Постановка ${n}`}))}},
      ...provider(projectAnswer()).output]})};
  },async url => url.endsWith('.jpg') ? {url,type:'image/jpeg',body:Buffer.concat([Buffer.from([255,216,255]),Buffer.alloc(1200)])}
    : {url,type:'text/html',body:Buffer.from(`<meta property="og:image" content="${url}.jpg">`)});
  const response=await app.post(request({version:2,operation:'chat',message:text}));
  assert.equal(response.status,200);
  const data=await response.json();
  assert.equal(paidCalls,1);assert.equal(data.sources.filter(s=>s.imageUrl).length,3);
  assert.equal(data.visualStatus,'available');assert.equal(data.mission,null);
  assert.match(data.reply,/Вот примеры для коллекции/);
  assert.ok(app.budget.state.spentUsd<0.06);
});
