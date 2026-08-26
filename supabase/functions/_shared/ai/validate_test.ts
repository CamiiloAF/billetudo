// Tests for the trust boundary with the model.
//
// Everything here guards a failure that is silent rather than loud: a budget
// 100x too small, an amount attached to a currency the user does not hold, an
// account id the model invented. None of these throw — they just produce a card
// that looks perfectly reasonable and is wrong.
//
// Run: deno test supabase/functions/_shared/ai/validate_test.ts

import { assertEquals, assertThrows } from 'jsr:@std/assert@1';

import { AiHttpError } from '../errors.ts';
import {
  indexSnapshot,
  parseChatRequest,
  toolRoundsSinceLastUser,
  validateProposal,
} from './validate.ts';

const snapshot = {
  currencies: [{ code: 'COP', decimals: 2 }],
  accounts: [{ id: 'acc-1', name: 'Bancolombia', currency: 'COP' }],
  categories: [{ id: 'cat-1', name: 'Comida', kind: 'expense' }],
  budgets: [{ id: 'bud-1', name: 'Comida', currency: 'COP' }],
};

const index = indexSnapshot(snapshot);

function budgetArgs(overrides: Record<string, unknown> = {}) {
  return {
    name: 'Comida',
    amountMinor: 45000000,
    currency: 'COP',
    period: 'monthly',
    rationale: 'Promedio de los ultimos 3 meses.',
    ...overrides,
  };
}

Deno.test('indexSnapshot collects ids and currencies at any depth', () => {
  assertEquals(index.ids.has('acc-1'), true);
  assertEquals(index.ids.has('cat-1'), true);
  assertEquals(index.ids.has('bud-1'), true);
  assertEquals(index.currencies.has('COP'), true);
  assertEquals(index.ids.has('nope'), false);
});

Deno.test('a well-formed budget proposal passes', () => {
  const result = validateProposal('propose_create_budget', budgetArgs(), index);
  assertEquals(result.ok, true);
  assertEquals(result.payload?.amountMinor, 45000000);
});

Deno.test('major units masquerading as minor units are refused', () => {
  // 45000 COP written as 45000 instead of 4500000 is the single most expensive
  // silent failure: the card reads "450,00" and the user taps confirm.
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ amountMinor: 45 }),
    index,
  );
  assertEquals(result.ok, false);
});

Deno.test('a fractional amount is refused rather than rounded', () => {
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ amountMinor: 4500.5 }),
    index,
  );
  assertEquals(result.ok, false);
});

Deno.test('a negative amount is refused', () => {
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ amountMinor: -4500000 }),
    index,
  );
  assertEquals(result.ok, false);
});

Deno.test('a currency the user does not hold is refused', () => {
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ currency: 'USD' }),
    index,
  );
  assertEquals(result.ok, false);
});

Deno.test('a malformed currency code is refused', () => {
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ currency: 'COPS' }),
    index,
  );
  assertEquals(result.ok, false);
});

Deno.test('a missing rationale is refused', () => {
  const args = budgetArgs();
  delete (args as Record<string, unknown>).rationale;
  assertEquals(validateProposal('propose_create_budget', args, index).ok, false);
});

Deno.test('hallucinated scope ids are dropped, not fatal', () => {
  // A budget scoped more broadly than intended is visible on the card and
  // recoverable; failing the whole proposal over one bad id is not.
  const result = validateProposal(
    'propose_create_budget',
    budgetArgs({ categoryIds: ['cat-1', 'ghost'], accountIds: ['ghost'] }),
    index,
  );
  assertEquals(result.ok, true);
  assertEquals(result.payload?.categoryIds, ['cat-1']);
  assertEquals(result.payload?.accountIds, []);
});

Deno.test('a transaction with an unknown account is refused', () => {
  // Unlike a budget scope, this one cannot be dropped: a movement has to land
  // somewhere, and guessing the account would be worse than asking again.
  const result = validateProposal('propose_create_transaction', {
    type: 'expense',
    amountMinor: 4500000,
    currency: 'COP',
    date: 1755100000,
    accountId: 'ghost',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, false);
});

Deno.test('a date in milliseconds is refused', () => {
  const result = validateProposal('propose_create_transaction', {
    type: 'expense',
    amountMinor: 4500000,
    currency: 'COP',
    date: 1755100000000,
    accountId: 'acc-1',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, false);
});

Deno.test('a valid transaction proposal passes and keeps its category', () => {
  const result = validateProposal('propose_create_transaction', {
    type: 'expense',
    amountMinor: 4500000,
    currency: 'COP',
    date: 1755100000,
    accountId: 'acc-1',
    categoryId: 'cat-1',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, true);
  assertEquals(result.payload?.categoryId, 'cat-1');
});

Deno.test('a category proposal needs no currency', () => {
  const result = validateProposal('propose_create_category', {
    name: 'Delivery',
    kind: 'expense',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, true);
});

Deno.test('an unknown parent category is refused', () => {
  const result = validateProposal('propose_create_category', {
    name: 'Delivery',
    kind: 'expense',
    parentId: 'ghost',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, false);
});

Deno.test('an unknown tool name is refused', () => {
  const result = validateProposal('propose_delete_everything', {
    currency: 'COP',
    rationale: 'x',
  }, index);
  assertEquals(result.ok, false);
});

Deno.test('tool rounds are counted only since the last user turn', () => {
  assertEquals(
    toolRoundsSinceLastUser([
      { role: 'user' },
      { role: 'assistant' },
      { role: 'tool' },
      { role: 'assistant' },
      { role: 'tool' },
    ]),
    2,
  );
  // Rounds from an earlier turn must not count against this one, or a long
  // conversation would lock itself out of ever reading again.
  assertEquals(
    toolRoundsSinceLastUser([
      { role: 'user' },
      { role: 'tool' },
      { role: 'tool' },
      { role: 'user' },
      { role: 'assistant' },
    ]),
    0,
  );
});

Deno.test('an empty transcript is rejected', () => {
  assertThrows(
    () => parseChatRequest({ messages: [], snapshot: {} }),
    AiHttpError,
  );
});

Deno.test('a future protocol version is rejected explicitly', () => {
  assertThrows(
    () =>
      parseChatRequest({
        protocolVersion: 99,
        messages: [{ role: 'user', content: 'hola' }],
        snapshot: {},
      }),
    AiHttpError,
  );
});

Deno.test('an over-long transcript is rejected', () => {
  const messages = Array.from({ length: 41 }, () => ({
    role: 'user',
    content: 'x',
  }));
  assertThrows(() => parseChatRequest({ messages, snapshot: {} }), AiHttpError);
});

Deno.test('a request without a snapshot object is rejected', () => {
  assertThrows(
    () => parseChatRequest({ messages: [{ role: 'user', content: 'hola' }] }),
    AiHttpError,
  );
});
