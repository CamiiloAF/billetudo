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

Deno.test(
  'a transaction proposal with no categoryId is refused, debtId or not — ' +
    'found live: it used to pass here and only fail at confirm time, ' +
    'on-device, as an opaque "no se pudo guardar" (TransactionDraft refuses ' +
    'an income/expense with no category)',
  () => {
    const base = {
      type: 'expense',
      amountMinor: 4500000,
      currency: 'COP',
      date: 1755100000,
      accountId: 'acc-1',
      rationale: 'x',
    };
    const plain = validateProposal('propose_create_transaction', base, index);
    assertEquals(plain.ok, false);

    const withDebt = validateProposal(
      'propose_create_transaction',
      { ...base, debtId: 'debt-1' },
      index,
    );
    assertEquals(withDebt.ok, false);
  },
);

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

// Linking an existing movement to a debt carries no amount of its own, so it
// is exempt from the currency check every other proposal must pass. Without
// the exemption the tool would be refused 100% of the time with a message
// about ISO 4217 — a failure mode that looks like the model misbehaving.
Deno.test('linking a movement to a debt needs no currency', () => {
  const index = indexSnapshot({
    accounts: [{ id: 'acc-1', currency: 'COP' }],
    debts: [{ id: 'debt-1' }],
    recent: [{ id: 'tx-1' }],
  });

  const ok = validateProposal(
    'propose_link_transaction_to_debt',
    { transactionId: 'tx-1', debtId: 'debt-1', rationale: 'es el abono' },
    index,
  );

  assertEquals(ok.ok, true);
  assertEquals(ok.payload?.transactionId, 'tx-1');
  assertEquals(ok.payload?.debtId, 'debt-1');
});

Deno.test('both ids of a debt link must come from the client', () => {
  const index = indexSnapshot({
    accounts: [{ id: 'acc-1', currency: 'COP' }],
    debts: [{ id: 'debt-1' }],
    recent: [{ id: 'tx-1' }],
  });

  const invented = validateProposal(
    'propose_link_transaction_to_debt',
    { transactionId: 'tx-999', debtId: 'debt-1', rationale: 'x' },
    index,
  );
  assertEquals(invented.ok, false);

  const inventedDebt = validateProposal(
    'propose_link_transaction_to_debt',
    { transactionId: 'tx-1', debtId: 'debt-999', rationale: 'x' },
    index,
  );
  assertEquals(inventedDebt.ok, false);
});

// A movement born linked: the debt id must survive validation, and an unknown
// one is refused rather than dropped — silently unlinking it would make the
// confirmation card promise something that then does not happen.
Deno.test('a transaction proposal carries an optional debtId', () => {
  const index = indexSnapshot({
    accounts: [{ id: 'acc-1', currency: 'COP' }],
    categories: [{ id: 'cat-1', kind: 'expense' }],
    debts: [{ id: 'debt-1' }],
  });
  const base = {
    type: 'expense',
    amountMinor: 284000000,
    currency: 'COP',
    date: 1756600000,
    accountId: 'acc-1',
    categoryId: 'cat-1',
    rationale: 'abono a capital',
  };

  const linked = validateProposal(
    'propose_create_transaction',
    { ...base, debtId: 'debt-1' },
    index,
  );
  assertEquals(linked.ok, true);
  assertEquals(linked.payload?.debtId, 'debt-1');

  const unlinked = validateProposal('propose_create_transaction', base, index);
  assertEquals(unlinked.ok, true);
  assertEquals(unlinked.payload?.debtId, undefined);

  const bogus = validateProposal(
    'propose_create_transaction',
    { ...base, debtId: 'debt-999' },
    index,
  );
  assertEquals(bogus.ok, false);
});

Deno.test('a request without a snapshot object is rejected', () => {
  assertThrows(
    () => parseChatRequest({ messages: [{ role: 'user', content: 'hola' }] }),
    AiHttpError,
  );
});

// `notesAccessEnabled` decides which version of the prompt's "buscar algo por
// como la persona lo llama" section ships. Anything other than a literal
// `true` has to land on the private reading: a client that omits the field, an
// older build that never heard of it, or a truthy-but-not-true value must not
// make the prompt tell the model it may read free-text notes.
Deno.test('notesAccessEnabled is off unless the client sends exactly true', () => {
  const base = {
    snapshot: {},
    messages: [{ role: 'user', content: 'hola' }],
  };

  assertEquals(parseChatRequest(base).notesAccessEnabled, false);
  assertEquals(
    parseChatRequest({ ...base, notesAccessEnabled: false }).notesAccessEnabled,
    false,
  );
  assertEquals(
    parseChatRequest({ ...base, notesAccessEnabled: 'true' }).notesAccessEnabled,
    false,
  );
  assertEquals(
    parseChatRequest({ ...base, notesAccessEnabled: 1 }).notesAccessEnabled,
    false,
  );
  assertEquals(
    parseChatRequest({ ...base, notesAccessEnabled: true }).notesAccessEnabled,
    true,
  );
});
