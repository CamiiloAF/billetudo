// Google Gemini adapter.
//
// Three Gemini-specific traps are handled here rather than leaking upward:
//
//  1. **No tool-call ids.** Gemini matches a `functionResponse` to its
//     `functionCall` by NAME alone. We synthesise `tc_<content>_<part>` ids on
//     the way out so the rest of the codebase can speak in ids, and drop them
//     on the way in. The ambiguity that remains — the same tool called twice in
//     one round — is closed by refusing duplicates (see `toContents`), because
//     the alternative is the model silently receiving the wrong result.
//  2. **`functionResponse.response` must be a JSON object**, never a string or
//     a bare array. Arrays get wrapped in `{items: [...]}`.
//  3. **Schemas are an OpenAPI 3.0 subset.** Enforced at the source in
//     `tools.ts`; nothing is rewritten here.

import { AiProvider } from './provider.ts';
import {
  AiFinishReason,
  AiMessage,
  AiProviderError,
  AiRequest,
  AiResult,
  AiToolCall,
} from './types.ts';

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';

interface GeminiPart {
  text?: string;
  functionCall?: { name: string; args?: Record<string, unknown> };
  functionResponse?: { name: string; response: Record<string, unknown> };
}

interface GeminiContent {
  role: 'user' | 'model';
  parts: GeminiPart[];
}

export class GeminiProvider implements AiProvider {
  constructor(
    readonly model: string,
    private readonly apiKey: string,
  ) {}

  readonly id = 'gemini';

  async generate(request: AiRequest): Promise<AiResult> {
    const body: Record<string, unknown> = {
      systemInstruction: { parts: [{ text: request.system }] },
      contents: toContents(request.messages),
      generationConfig: {
        temperature: request.temperature ?? 0.4,
        maxOutputTokens: request.maxOutputTokens ?? 1200,
      },
    };

    // An empty `functionDeclarations` array is rejected, so the tools block is
    // omitted entirely when the caller asked for none.
    if (request.tools.length > 0 && request.toolMode !== 'none') {
      body.tools = [{ functionDeclarations: request.tools }];
      body.toolConfig = {
        functionCallingConfig: { mode: toGeminiMode(request.toolMode) },
      };
    }

    const payload = await this.post(body, request.timeoutMs);
    return toResult(payload);
  }

  private async post(
    body: unknown,
    timeoutMs: number,
  ): Promise<Record<string, unknown>> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    let response: Response;
    try {
      response = await fetch(
        `${ENDPOINT}/${this.model}:generateContent`,
        {
          method: 'POST',
          // Header, never a query parameter: an api key in a URL ends up in
          // every proxy and access log between here and Google.
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': this.apiKey,
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        },
      );
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        throw new AiProviderError('timeout', 'provider timed out');
      }
      throw new AiProviderError('unavailable', `provider unreachable: ${error}`);
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      throw await providerErrorFor(response);
    }

    try {
      return await response.json() as Record<string, unknown>;
    } catch (_) {
      throw new AiProviderError('bad_response', 'provider returned invalid JSON');
    }
  }
}

function toGeminiMode(mode: 'auto' | 'none' | 'required'): string {
  switch (mode) {
    case 'auto':
      return 'AUTO';
    case 'none':
      return 'NONE';
    case 'required':
      return 'ANY';
  }
}

/// Maps the shared transcript onto Gemini's `contents`.
///
/// Note the asymmetry: a `tool` message becomes a **user** turn carrying a
/// `functionResponse`. That is Gemini's convention, not a mistake — the model
/// only ever speaks as `model`, and everything fed back to it is `user`.
export function toContents(messages: AiMessage[]): GeminiContent[] {
  const contents: GeminiContent[] = [];

  for (const message of messages) {
    if (message.role === 'user') {
      contents.push({ role: 'user', parts: [{ text: message.content ?? '' }] });
      continue;
    }

    if (message.role === 'assistant') {
      const parts: GeminiPart[] = [];
      if (message.content) parts.push({ text: message.content });
      // Duplicate names in one assistant turn would make the responses
      // unmatchable (see the header): keep the first, drop the rest.
      const seen = new Set<string>();
      for (const call of message.toolCalls ?? []) {
        if (seen.has(call.name)) continue;
        seen.add(call.name);
        parts.push({ functionCall: { name: call.name, args: call.arguments } });
      }
      if (parts.length === 0) parts.push({ text: '' });
      contents.push({ role: 'model', parts });
      continue;
    }

    // role === 'tool'
    contents.push({
      role: 'user',
      parts: [{
        functionResponse: {
          name: message.name ?? '',
          response: asResponseObject(message.result),
        },
      }],
    });
  }

  return contents;
}

/// Gemini requires `functionResponse.response` to be a JSON object. A tool that
/// naturally returns a list gets wrapped rather than rejected.
function asResponseObject(result: unknown): Record<string, unknown> {
  if (Array.isArray(result)) return { items: result };
  if (result === null || result === undefined) return {};
  if (typeof result === 'object') return result as Record<string, unknown>;
  return { value: result };
}

function toResult(payload: Record<string, unknown>): AiResult {
  const candidates = payload.candidates as Array<Record<string, unknown>> | undefined;

  const usage = payload.usageMetadata as Record<string, number> | undefined;
  const tokens = {
    promptTokens: usage?.promptTokenCount ?? 0,
    completionTokens: usage?.candidatesTokenCount ?? 0,
  };

  if (!candidates || candidates.length === 0) {
    // A prompt blocked before generation comes back with no candidates at all
    // and a `promptFeedback.blockReason`. That is a refusal, not an outage.
    const feedback = payload.promptFeedback as Record<string, unknown> | undefined;
    if (feedback?.blockReason) {
      return { text: '', toolCalls: [], usage: tokens, finish: 'safety' };
    }
    throw new AiProviderError('bad_response', 'provider returned no candidates');
  }

  const candidate = candidates[0];
  const content = candidate.content as GeminiContent | undefined;
  const parts = content?.parts ?? [];

  const textChunks: string[] = [];
  const toolCalls: AiToolCall[] = [];

  parts.forEach((part, index) => {
    if (typeof part.text === 'string' && part.text.length > 0) {
      textChunks.push(part.text);
    }
    if (part.functionCall) {
      toolCalls.push({
        id: `tc_0_${index}`,
        name: part.functionCall.name,
        arguments: part.functionCall.args ?? {},
      });
    }
  });

  return {
    text: textChunks.join('').trim(),
    toolCalls,
    usage: tokens,
    finish: toFinishReason(candidate.finishReason, toolCalls.length > 0),
  };
}

function toFinishReason(raw: unknown, hasToolCalls: boolean): AiFinishReason {
  if (hasToolCalls) return 'tool_calls';
  switch (raw) {
    case 'STOP':
      return 'stop';
    case 'MAX_TOKENS':
      return 'length';
    case 'SAFETY':
    case 'PROHIBITED_CONTENT':
    case 'BLOCKLIST':
    case 'SPII':
      return 'safety';
    default:
      return 'other';
  }
}

async function providerErrorFor(response: Response): Promise<AiProviderError> {
  // The body may quote the request back, which for us means the user's own
  // financial data. It is parsed for the retry hint and then dropped — never
  // forwarded to the client, never logged whole.
  let body: Record<string, unknown> | undefined;
  try {
    body = await response.json() as Record<string, unknown>;
  } catch (_) {
    body = undefined;
  }

  if (response.status === 401 || response.status === 403) {
    return new AiProviderError('auth', 'provider rejected the api key');
  }
  if (response.status === 429) {
    return new AiProviderError(
      'rate_limited',
      'provider rate limited',
      retryDelaySeconds(body) ?? 30,
    );
  }
  if (response.status >= 500) {
    return new AiProviderError('unavailable', `provider error ${response.status}`);
  }
  return new AiProviderError('bad_response', `provider error ${response.status}`);
}

/// Digs `RetryInfo.retryDelay` ("17s") out of a Google API error envelope.
export function retryDelaySeconds(
  body: Record<string, unknown> | undefined,
): number | undefined {
  const error = body?.error as Record<string, unknown> | undefined;
  const details = error?.details as Array<Record<string, unknown>> | undefined;
  if (!details) return undefined;

  for (const detail of details) {
    const delay = detail.retryDelay;
    if (typeof delay === 'string') {
      const seconds = Number.parseFloat(delay.replace(/s$/, ''));
      if (Number.isFinite(seconds)) return seconds;
    }
  }
  return undefined;
}
