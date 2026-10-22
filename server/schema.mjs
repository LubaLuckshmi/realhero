const string = { type: 'string', maxLength: 8000 };
const strings = { type: 'array', maxItems: 12, items: string };
const object = (properties) => ({
  type: 'object', properties, required: Object.keys(properties), additionalProperties: false,
});
const nullable = (schema) => ({ anyOf: [schema, { type: 'null' }] });
const step = object({ id: string, title: string, hint: string });
const material = object({
  id: string, label: string, text: string,
  kind: { type: 'string', enum: ['message', 'questions', 'checklist', 'draft'] },
});
const mission = object({
  id: string, goalId: string, title: string, why: string,
  minutes: { type: 'integer', minimum: 1, maximum: 180 },
  oneAction: string, lightAction: string,
  steps: { type: 'array', minItems: 1, maxItems: 5, items: step },
  materials: { type: 'array', minItems: 1, maxItems: 6, items: material },
  status: { type: 'string', enum: ['prepared'] },
  chapter: string, ability: string,
  evidence: { type: 'array', minItems: 1, maxItems: 6, items: object({ quote: string }) },
  contactNames: strings,
});

export const LEIA_SCHEMA = object({
  reply: { type: 'string', maxLength: 420 },
  quickReplies: { type: 'array', maxItems: 3, items: { type: 'string', maxLength: 48 } },
  goal: nullable(object({ id: string, title: string, context: string, createdAt: string })),
  mission: nullable(mission),
  understanding: string,
  assumptions: strings,
  needsClarification: { type: 'boolean' },
  nextDirection: string,
  reflection: nullable(object({
    whatHappened: string, learned: string, goalImpact: string, nextMove: string,
    realChange: { type: 'boolean' },
  })),
  contextUpdates: {
    type: 'array', maxItems: 10,
    items: object({ text: string, sourceQuote: string }),
  },
});

// Validate even structured outputs; refusals and interrupted output do not follow the schema.
export function conforms(value, schema) {
  if (schema.anyOf) return schema.anyOf.some((option) => conforms(value, option));
  if (schema.type === 'null') return value === null;
  if (schema.type === 'string') {
    return typeof value === 'string' && value.length <= (schema.maxLength ?? Infinity)
      && (!schema.enum || schema.enum.includes(value));
  }
  if (schema.type === 'boolean') return typeof value === 'boolean';
  if (schema.type === 'integer') return Number.isInteger(value)
    && value >= (schema.minimum ?? -Infinity) && value <= (schema.maximum ?? Infinity);
  if (schema.type === 'array') return Array.isArray(value)
    && value.length >= (schema.minItems ?? 0) && value.length <= (schema.maxItems ?? Infinity)
    && value.every((item) => conforms(item, schema.items));
  if (schema.type === 'object') {
    return value !== null && typeof value === 'object' && !Array.isArray(value)
      && schema.required.every((key) => Object.hasOwn(value, key))
      && Object.keys(value).every((key) => Object.hasOwn(schema.properties, key))
      && Object.entries(schema.properties).every(([key, child]) => conforms(value[key], child));
  }
  return false;
}


export function projectSchema(operation) {
  return object({
    ...LEIA_SCHEMA.properties,
    reply: {type: 'string', maxLength: 3200},
    mission: operation === 'chat' ? {type: 'null'} : LEIA_SCHEMA.properties.mission,
    workspace: object({
      summary: {type: 'string', maxLength: 1200},
      roadmap: {type: 'array', maxItems: 8, items: object({id: string, title: {type:'string',maxLength:120}, detail: {type:'string',maxLength:800}})},
      drafts: {type:'array',maxItems:5,items:object({title:{type:'string',maxLength:160},text:string})},
    }),
  });
}
