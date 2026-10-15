import { mkdirSync, readFileSync, writeFileSync, renameSync, openSync, closeSync, unlinkSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { PublicError } from './errors.mjs';

// Fixed allowlist avoids silently applying cheap-model prices to an expensive model.
export const MODEL_RATES = Object.freeze({
  'gpt-4.1-mini': { input: 0.40, output: 1.60 },
  'gpt-4.1-mini-2025-04-14': { input: 0.40, output: 1.60 },
});

export class BudgetLedger {
  constructor({ path, ceilingUsd }) {
    this.path = path ? resolve(path) : null;
    this.ceilingUsd = ceilingUsd;
    this.state = { version: 1, spentUsd: 0, reservations: {} };
    this.lockPath = this.path ? `${this.path}.lock` : null;
    this.lockFd = null;
    if (this.path) {
      mkdirSync(dirname(this.path), { recursive: true, mode: 0o700 });
      // One process owns one ledger. A second worker must not race and bypass the ceiling.
      try { this.lockFd = openSync(this.lockPath, 'wx', 0o600); }
      catch { throw new Error('Usage ledger already locked. Run one server process per ledger.'); }
      try {
        try {
          const state = JSON.parse(readFileSync(this.path, 'utf8'));
          if (state.version !== 1 || !Number.isFinite(state.spentUsd) || state.spentUsd < 0
            || !state.reservations || typeof state.reservations !== 'object') throw new Error('Invalid ledger');
          this.state = state;
        } catch (error) {
          if (error.code !== 'ENOENT') throw new Error('Usage ledger unreadable; refusing to reset budget.');
        }
        // An interrupted request may have been billed. Existing reservations stay counted.
        this.persist();
      } catch (error) { this.close(); throw error; }
    }
  }

  persist() {
    if (!this.path) return;
    const temporary = `${this.path}.${randomUUID()}.tmp`;
    writeFileSync(temporary, JSON.stringify(this.state), { mode: 0o600 });
    renameSync(temporary, this.path);
  }

  reserve(usd) {
    if (!(this.ceilingUsd > 0)) {
      throw new PublicError(503, 'budget_not_approved', 'Платные запросы пока выключены. Тестовый бюджет ещё не согласован.');
    }
    if (this.state.spentUsd + usd > this.ceilingUsd) {
      throw new PublicError(429, 'budget_exhausted', 'Тестовый бюджет исчерпан. Миссии и результаты сохранены.');
    }
    const id = randomUUID();
    this.state.spentUsd += usd;
    this.state.reservations[id] = usd;
    // Reserve BEFORE dispatching a billable request; persistence failure prevents dispatch.
    this.persist();
    return id;
  }

  settle(id, actualUsd) {
    const reserved = this.state.reservations[id];
    if (typeof reserved !== 'number' || !Number.isFinite(actualUsd) || actualUsd < 0) return;
    // Do not release funds if the provider reports usage above our conservative estimate.
    if (actualUsd > reserved) {
      this.state.spentUsd += actualUsd - reserved;
    } else this.state.spentUsd -= reserved - actualUsd;
    delete this.state.reservations[id];
    this.state.spentUsd = Math.max(0, this.state.spentUsd);
    this.persist();
  }

  close() {
    if (this.lockFd !== null) {
      closeSync(this.lockFd); this.lockFd = null;
      try { unlinkSync(this.lockPath); } catch { /* closed or interrupted elsewhere */ }
    }
  }
}

export function conservativeCost(payload, model, maxOutputTokens) {
  const rates = MODEL_RATES[model];
  if (!rates) throw new PublicError(503, 'model_not_allowed', 'Серверная модель не настроена для тестового бюджета.');
  // Each UTF-8 byte as a possible token + envelope allowance. Cached tokens use full input rate.
  const inputTokenCeiling = Buffer.byteLength(JSON.stringify(payload), 'utf8') + 1024;
  return (inputTokenCeiling * rates.input + maxOutputTokens * rates.output) / 1_000_000;
}

export function usageCost(usage, model) {
  const rates = MODEL_RATES[model];
  if (!rates || !Number.isInteger(usage?.input_tokens) || !Number.isInteger(usage?.output_tokens)
    || usage.input_tokens < 0 || usage.output_tokens < 0) return null;
  return (usage.input_tokens * rates.input + usage.output_tokens * rates.output) / 1_000_000;
}
