// Tests for the Gemini shim's three known traps. All of these fail silently in
// production if they regress: the model simply answers from the wrong data.
//
// Run: deno test supabase/functions/_shared/ai/gemini_test.ts

import { assertEquals } from 'jsr:@std/assert@1';

import { retryDelaySeconds, toContents } from './gemini.ts';

Deno.test('a tool message becomes a user turn carrying a functionResponse', () => {
  // Gemini's convention, not a mistake: the model only ever speaks as `model`,
  // and everything fed back to it arrives as `user`.
  const contents = toContents([
    { role: 'user', content: 'hola' },
    {
      role: 'assistant',
      content: '',
      toolCalls: [{ id: 'tc_0_0', name: 'get_transactions', arguments: { limit: 5 } }],
    },
    {
      role: 'tool',
      toolCallId: 'tc_0_0',
      name: 'get_transactions',
      result: { count: 2 },
    },
  ]);

  assertEquals(contents.length, 3);
  assertEquals(contents[0].role, 'user');
  assertEquals(contents[1].role, 'model');
  assertEquals(contents[1].parts[0].functionCall?.name, 'get_transactions');
  assertEquals(contents[2].role, 'user');
  assertEquals(contents[2].parts[0].functionResponse?.name, 'get_transactions');
});

Deno.test('an array tool result is wrapped in an object', () => {
  // Gemini rejects a bare array in functionResponse.response.
  const contents = toContents([
    { role: 'tool', name: 'get_transactions', result: [{ id: 'a' }] },
  ]);
  assertEquals(contents[0].parts[0].functionResponse?.response, {
    items: [{ id: 'a' }],
  });
});

Deno.test('a null tool result becomes an empty object', () => {
  const contents = toContents([
    { role: 'tool', name: 'get_goal_detail', result: null },
  ]);
  assertEquals(contents[0].parts[0].functionResponse?.response, {});
});

Deno.test('duplicate tool names in one assistant turn are collapsed', () => {
  // Gemini matches responses to calls by NAME alone, so two calls to the same
  // tool in one round cannot be told apart. Keeping the first is the only
  // option that never feeds the model a crossed result.
  const contents = toContents([
    {
      role: 'assistant',
      content: 'veamos',
      toolCalls: [
        { id: 'a', name: 'get_transactions', arguments: { limit: 5 } },
        { id: 'b', name: 'get_transactions', arguments: { limit: 50 } },
      ],
    },
  ]);

  const calls = contents[0].parts.filter((part) => part.functionCall);
  assertEquals(calls.length, 1);
  assertEquals(calls[0].functionCall?.args, { limit: 5 });
});

Deno.test('an assistant turn with no content still produces a part', () => {
  // An empty parts array is rejected by the API.
  const contents = toContents([{ role: 'assistant' }]);
  assertEquals(contents[0].parts.length, 1);
});

Deno.test('retryDelaySeconds reads RetryInfo out of a Google error envelope', () => {
  assertEquals(
    retryDelaySeconds({
      error: {
        details: [
          { '@type': 'type.googleapis.com/google.rpc.QuotaFailure' },
          { '@type': 'type.googleapis.com/google.rpc.RetryInfo', retryDelay: '17s' },
        ],
      },
    }),
    17,
  );
  assertEquals(retryDelaySeconds(undefined), undefined);
  assertEquals(retryDelaySeconds({ error: {} }), undefined);
});
