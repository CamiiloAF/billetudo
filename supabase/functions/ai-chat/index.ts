// The AI assistant's only endpoint (Fase A).
//
// This function is a STATELESS BROKER. It never reads a financial table: the
// app owns the transcript and resends it, and the app resolves every read tool
// against its own local database. All this function does is check the gate,
// build the prompt, talk to the provider, record usage metadata, and translate
// the answer back.
//
// That is a privacy decision before it is an architectural one. Nothing the
// user says, and nothing about their money, is stored on the server — which is
// what the privacy policy is allowed to promise only for as long as this stays
// true. If a future change starts persisting transcripts "just for debugging",
// the policy becomes false the same day.
//
// `verify_jwt: true` is set at deploy time, so the gateway rejects an
// unauthenticated request before this code runs. We still resolve the user from
// the JWT ourselves (see `_shared/auth.ts`): the body never says who is calling.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { SupabaseClient } from 'jsr:@supabase/supabase-js@2';

import { requireUser } from '../_shared/auth.ts';
import { AiHttpError } from '../_shared/errors.ts';
import { errorResponse, json, readJsonBody, responseForThrown } from '../_shared/http.ts';
import { getProvider, maxToolRounds, requestTimeoutMs } from '../_shared/ai/factory.ts';
import { buildSystemPrompt } from '../_shared/ai/prompt.ts';
import { AiProvider } from '../_shared/ai/provider.ts';
import {
  ALL_TOOLS,
  isWriteTool,
  proposalKindFor,
  READ_TOOLS,
} from '../_shared/ai/tools.ts';
import { AiProviderError, AiResult, AiToolCall } from '../_shared/ai/types.ts';
import {
  ChatRequest,
  indexSnapshot,
  parseChatRequest,
  PROTOCOL_VERSION,
  toolRoundsSinceLastUser,
  validateProposal,
} from '../_shared/ai/validate.ts';

/// Found live: a rejected proposal's retry, or a plain turn with no tool
/// calls, can both come back from the provider with `text === ''` — the
/// model producing genuinely nothing (not an error, not a safety block,
/// just an empty string). Left as `content: ''`, that rendered as a
/// completely blank assistant bubble on device, with no card and no way for
/// the user to tell what happened. Every terminal "message" response
/// substitutes this instead of ever sending an empty string down the wire.
const EMPTY_RESPONSE_FALLBACK =
  'No logré armar una respuesta esta vez. ¿Puedes reformular la pregunta?';

interface AccessState {
  enabled: boolean;
  tier: string;
  dailyMessageLimit: number;
  usedToday: number;
}

interface UsageRecord {
  outcome:
    | 'ok'
    | 'blocked'
    | 'rate_limited'
    | 'timeout'
    | 'provider_error'
    | 'invalid';
  errorCode?: string;
  promptTokens?: number;
  completionTokens?: number;
  toolRounds: number;
  proposalsCount: number;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return errorResponse('invalid_request', 'method not allowed');
  }

  const startedAt = Date.now();
  let request: ChatRequest | undefined;
  let provider: AiProvider | undefined;
  let admin: SupabaseClient | undefined;
  let userId: string | undefined;

  try {
    const caller = await requireUser(req);
    admin = caller.admin;
    userId = caller.userId;

    const access = await readAccessState(admin, userId);
    if (!access.enabled) {
      // A closed gate must not cost a single token, so this check sits before
      // anything touches the provider.
      return errorResponse(
        'ai_not_enabled',
        'the assistant is not enabled for this account',
      );
    }
    if (
      access.dailyMessageLimit > 0
      && access.usedToday >= access.dailyMessageLimit
    ) {
      // Fase B turns this into a real quota with ads and Premium behind it.
      // It is enforced from day one anyway: on the free provider tier the rate
      // limit is shared across every user, so one runaway client would take the
      // assistant down for everybody.
      return errorResponse('quota_exceeded', 'daily limit reached', 3600);
    }

    const body = await readJsonBody(req);
    request = parseChatRequest(body);
    provider = getProvider();

    const rounds = toolRoundsSinceLastUser(request.messages);
    const exhausted = rounds >= maxToolRounds();

    const system = buildSystemPrompt({
      locale: request.locale,
      timezone: request.timezone,
      nowSeconds: Math.floor(startedAt / 1000),
      notesAccessEnabled: request.notesAccessEnabled,
      snapshotJson: JSON.stringify(request.snapshot),
    });

    const first = await provider.generate({
      system,
      messages: request.messages,
      tools: ALL_TOOLS,
      // Out of read rounds: the model may still answer and may still propose,
      // but it cannot ask for more data. Without this a buggy client could
      // ping-pong forever on someone else's quota.
      toolMode: exhausted ? 'none' : 'auto',
      timeoutMs: requestTimeoutMs(),
    });

    const outcome = await resolveTurn({
      provider,
      system,
      request,
      first,
      exhausted,
      rounds,
    });

    await recordUsage(admin, userId, request, provider, startedAt, outcome.usage);
    return json(outcome.body);
  } catch (error) {
    const mapped = mapThrown(error);

    if (admin && userId) {
      await recordUsage(admin, userId, request, provider, startedAt, {
        outcome: mapped.usageOutcome,
        errorCode: mapped.errorCode,
        toolRounds: 0,
        proposalsCount: 0,
      });
    }

    return mapped.response;
  }
});

// ---------------------------------------------------------------------------
// Turn resolution
// ---------------------------------------------------------------------------

interface TurnOutcome {
  body: Record<string, unknown>;
  usage: UsageRecord;
}

/// At most TWO provider calls happen inside one invocation: the first one, plus
/// either a closing call with tools switched off (to get the prose that goes
/// with a proposal card) or a single retry after an invalid proposal. Read
/// rounds are not counted here — each one is a separate HTTP request from the
/// app, bounded by `toolRoundsSinceLastUser`.
async function resolveTurn(args: {
  provider: AiProvider;
  system: string;
  request: ChatRequest;
  first: AiResult;
  exhausted: boolean;
  rounds: number;
}): Promise<TurnOutcome> {
  const { provider, system, request, first, exhausted, rounds } = args;

  if (first.finish === 'safety') {
    return {
      body: response({
        finishReason: 'blocked',
        content: '',
        usage: first,
      }),
      usage: {
        outcome: 'blocked',
        promptTokens: first.usage.promptTokens,
        completionTokens: first.usage.completionTokens,
        toolRounds: rounds,
        proposalsCount: 0,
      },
    };
  }

  const writeCalls = first.toolCalls.filter((call) => isWriteTool(call.name));
  const readCalls = first.toolCalls.filter((call) => !isWriteTool(call.name));

  if (writeCalls.length > 0) {
    return await resolveProposals({
      provider,
      system,
      request,
      first,
      writeCalls,
      rounds,
    });
  }

  if (readCalls.length > 0 && !exhausted) {
    const known = readCalls.filter((call) =>
      READ_TOOLS.some((tool) => tool.name === call.name)
    );
    if (known.length > 0) {
      return {
        body: response({
          finishReason: 'tool_calls',
          content: first.text,
          usage: first,
          toolCalls: dedupeByName(known),
        }),
        usage: {
          outcome: 'ok',
          promptTokens: first.usage.promptTokens,
          completionTokens: first.usage.completionTokens,
          toolRounds: rounds,
          proposalsCount: 0,
        },
      };
    }
  }

  return {
    body: response({
      finishReason: exhausted && readCalls.length > 0 ? 'max_iterations' : 'message',
      content: first.text || EMPTY_RESPONSE_FALLBACK,
      usage: first,
    }),
    usage: {
      outcome: 'ok',
      promptTokens: first.usage.promptTokens,
      completionTokens: first.usage.completionTokens,
      toolRounds: rounds,
      proposalsCount: 0,
    },
  };
}

async function resolveProposals(args: {
  provider: AiProvider;
  system: string;
  request: ChatRequest;
  first: AiResult;
  writeCalls: AiToolCall[];
  rounds: number;
}): Promise<TurnOutcome> {
  const { provider, system, request, first, writeCalls, rounds } = args;
  const index = indexSnapshot(request.snapshot);

  // One proposal per answer is the rule the prompt states; enforce it here so a
  // model that ignores it cannot flood the conversation with cards.
  const call = writeCalls[0];
  const validation = validateProposal(call.name, call.arguments, index);

  if (!validation.ok) {
    // Hand the reason back and let the model try once. This is the one retry
    // budget an invocation gets — if the second attempt is also broken, the
    // user gets prose and no card, which is a far better failure than a card
    // built on a hallucinated account id.
    const retry = await provider.generate({
      system,
      messages: [
        ...request.messages,
        { role: 'assistant', content: first.text, toolCalls: [call] },
        {
          role: 'tool',
          toolCallId: call.id,
          name: call.name,
          result: { error: 'invalid_proposal', reason: validation.reason },
        },
      ],
      tools: ALL_TOOLS,
      toolMode: 'auto',
      timeoutMs: requestTimeoutMs(),
    });

    const retryCall = retry.toolCalls.find((each) => isWriteTool(each.name));
    const retryValidation = retryCall
      ? validateProposal(retryCall.name, retryCall.arguments, index)
      : undefined;

    if (retryCall && retryValidation?.ok) {
      return proposalOutcome({
        text: retry.text || first.text,
        call: retryCall,
        payload: retryValidation.payload!,
        usage: retry,
        rounds,
      });
    }

    return {
      body: response({
        finishReason: 'message',
        content: retry.text || first.text || EMPTY_RESPONSE_FALLBACK,
        usage: retry,
      }),
      usage: {
        outcome: 'invalid',
        errorCode: 'invalid_proposal',
        promptTokens: retry.usage.promptTokens,
        completionTokens: retry.usage.completionTokens,
        toolRounds: rounds,
        proposalsCount: 0,
      },
    };
  }

  // A proposal with no prose around it reads as a bare form. Ask once more with
  // tools switched off purely to get the sentence that introduces the card.
  let text = first.text;
  let usage = first;
  if (!text) {
    const closing = await provider.generate({
      system,
      messages: [
        ...request.messages,
        { role: 'assistant', content: '', toolCalls: [call] },
        {
          role: 'tool',
          toolCallId: call.id,
          name: call.name,
          result: {
            status: 'pending_user_confirmation',
            note:
              'La propuesta ya se le mostro al usuario como tarjeta. Escribe '
              + 'solo la frase que la acompana, sin repetir los datos.',
          },
        },
      ],
      tools: [],
      toolMode: 'none',
      timeoutMs: requestTimeoutMs(),
    });
    text = closing.text;
    usage = closing;
  }

  return proposalOutcome({
    text,
    call,
    payload: validation.payload!,
    usage,
    rounds,
  });
}

function proposalOutcome(args: {
  text: string;
  call: AiToolCall;
  payload: Record<string, unknown>;
  usage: AiResult;
  rounds: number;
}): TurnOutcome {
  const { text, call, payload, usage, rounds } = args;
  const rationale = payload.rationale;

  return {
    body: response({
      finishReason: 'message',
      content: text,
      usage,
      proposals: [{
        id: call.id,
        kind: proposalKindFor(call.name),
        // The card's heading is the model's own sentence, but every field
        // below it comes from the validated payload — never from free text.
        title: typeof rationale === 'string' ? rationale : '',
        payload,
      }],
    }),
    usage: {
      outcome: 'ok',
      promptTokens: usage.usage.promptTokens,
      completionTokens: usage.usage.completionTokens,
      toolRounds: rounds,
      proposalsCount: 1,
    },
  };
}

/// Gemini matches tool responses by name, so two calls to the same tool in one
/// round cannot be told apart. Keep the first and drop the rest rather than let
/// the model receive a crossed result and answer confidently from it.
function dedupeByName(calls: AiToolCall[]): AiToolCall[] {
  const seen = new Set<string>();
  return calls.filter((call) => {
    if (seen.has(call.name)) return false;
    seen.add(call.name);
    return true;
  });
}

function response(args: {
  finishReason: string;
  content: string;
  usage: AiResult;
  toolCalls?: AiToolCall[];
  proposals?: unknown[];
}): Record<string, unknown> {
  return {
    protocolVersion: PROTOCOL_VERSION,
    finishReason: args.finishReason,
    message: {
      role: 'assistant',
      content: args.content,
      proposals: args.proposals ?? [],
    },
    toolCalls: args.toolCalls ?? [],
    usage: {
      promptTokens: args.usage.usage.promptTokens,
      completionTokens: args.usage.usage.completionTokens,
    },
  };
}

// ---------------------------------------------------------------------------
// Gate and usage log
// ---------------------------------------------------------------------------

async function readAccessState(
  admin: SupabaseClient,
  userId: string,
): Promise<AccessState> {
  const { data, error } = await admin.rpc('ai_access_state', { p_user_id: userId });
  if (error) {
    console.error('ai_access_state failed', error.message);
    // Fail closed. An unreadable gate is not an open gate: the alternative is
    // serving a paid model to anyone whenever the database hiccups.
    throw new AiHttpError('internal', 'could not verify access');
  }

  const row = Array.isArray(data) ? data[0] : data;
  return {
    enabled: row?.enabled === true,
    tier: row?.tier ?? 'beta',
    dailyMessageLimit: row?.daily_message_limit ?? 0,
    usedToday: row?.used_today ?? 0,
  };
}

/// Metadata only — no message text, no snapshot, no proposals. Deliberately
/// insufficient to reconstruct a conversation.
///
/// A failure here never fails the turn: the user already has their answer, and
/// losing one log row is cheaper than losing the reply. In Fase B, when this
/// row is what a quota is counted from, that trade-off inverts.
async function recordUsage(
  admin: SupabaseClient,
  userId: string,
  request: ChatRequest | undefined,
  provider: AiProvider | undefined,
  startedAt: number,
  usage: UsageRecord,
): Promise<void> {
  try {
    await admin.from('ai_usage_log').insert({
      user_id: userId,
      conversation_id: request?.conversationId ?? null,
      provider: provider?.id ?? 'unknown',
      model: provider?.model ?? 'unknown',
      outcome: usage.outcome,
      error_code: usage.errorCode ?? null,
      prompt_tokens: usage.promptTokens ?? null,
      completion_tokens: usage.completionTokens ?? null,
      tool_rounds: usage.toolRounds,
      proposals_count: usage.proposalsCount,
      latency_ms: Date.now() - startedAt,
      client_version: request?.clientVersion ?? null,
    });
  } catch (error) {
    console.error('ai_usage_log insert failed', error);
  }
}

function mapThrown(error: unknown): {
  response: Response;
  usageOutcome: UsageRecord['outcome'];
  errorCode: string;
} {
  if (error instanceof AiProviderError) {
    switch (error.kind) {
      case 'rate_limited':
        return {
          response: errorResponse(
            'provider_rate_limited',
            'the assistant is busy right now',
            error.retryAfterSeconds,
          ),
          usageOutcome: 'rate_limited',
          errorCode: 'provider_rate_limited',
        };
      case 'timeout':
        return {
          response: errorResponse('provider_timeout', 'the assistant took too long'),
          usageOutcome: 'timeout',
          errorCode: 'provider_timeout',
        };
      case 'auth':
        // The api key is wrong or revoked. Never say so to the client — that is
        // a deployment problem, and the message would hint at the secret.
        console.error('provider rejected credentials');
        return {
          response: errorResponse('provider_unavailable', 'the assistant is unavailable'),
          usageOutcome: 'provider_error',
          errorCode: errorCodeWithDetail('provider_auth', error.detail),
        };
      default:
        return {
          response: errorResponse('provider_unavailable', 'the assistant is unavailable'),
          usageOutcome: 'provider_error',
          errorCode: errorCodeWithDetail(error.kind, error.detail),
        };
    }
  }

  if (error instanceof AiHttpError) {
    return {
      response: responseForThrown(error),
      usageOutcome: error.code === 'ai_not_enabled' ? 'blocked' : 'invalid',
      errorCode: error.code,
    };
  }

  return {
    response: responseForThrown(error),
    usageOutcome: 'invalid',
    errorCode: 'internal',
  };
}

/// `ai_usage_log.error_code` has no schema constraint, so folding the
/// provider's own HTTP status into it (`bad_response:404`, `auth:401`) is
/// free — no migration, and it is the only place that status survives past
/// this request. Without it, every non-5xx/401/403/429 failure collapsed
/// into a bare `bad_response`, indistinguishable from each other.
function errorCodeWithDetail(kind: string, detail: string | undefined): string {
  return detail ? `${kind}:${detail}` : kind;
}
