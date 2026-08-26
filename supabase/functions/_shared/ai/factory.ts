// Provider selection. Swapping vendors is an env var plus one new file that
// implements `AiProvider`; nothing in `ai-chat/index.ts` or in the Flutter app
// changes.

import { AiHttpError } from '../errors.ts';
import { GeminiProvider } from './gemini.ts';
import { AiProvider } from './provider.ts';

export function getProvider(): AiProvider {
  const id = Deno.env.get('AI_PROVIDER') ?? 'gemini';

  switch (id) {
    case 'gemini': {
      const apiKey = Deno.env.get('GEMINI_API_KEY');
      if (!apiKey) {
        // A missing secret is a deployment mistake, not a user-facing failure
        // mode — but it must not read as "the model is down", or nobody will
        // ever go looking for the real cause.
        console.error('GEMINI_API_KEY is not set for this project');
        throw new AiHttpError('internal', 'assistant is not configured');
      }
      const model = Deno.env.get('AI_MODEL') ?? 'gemini-2.5-flash';
      return new GeminiProvider(model, apiKey);
    }
    default:
      console.error(`unknown AI_PROVIDER: ${id}`);
      throw new AiHttpError('internal', 'assistant is not configured');
  }
}

export function requestTimeoutMs(): number {
  const raw = Number(Deno.env.get('AI_REQUEST_TIMEOUT_MS'));
  return Number.isFinite(raw) && raw > 0 ? raw : 25000;
}

/// How many `tool` messages may sit between the last user turn and now before
/// the model is cut off from asking for more. Counted over the transcript the
/// client sent, not within one invocation — each read round is its own HTTP
/// call, so this is the only place a runaway loop can be stopped.
export function maxToolRounds(): number {
  const raw = Number(Deno.env.get('AI_MAX_TOOL_ROUNDS'));
  return Number.isFinite(raw) && raw > 0 ? raw : 3;
}
