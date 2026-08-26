// Provider-agnostic shapes. Nothing below mentions Gemini on purpose: swapping
// the provider must be a new file plus an env var, never a change in the
// function that orchestrates the turn.

export type AiRole = 'user' | 'assistant' | 'tool';

export interface AiToolCall {
  /// Synthesised by the provider adapter when the underlying API has no tool
  /// call ids of its own (Gemini does not). Stable within one turn only.
  id: string;
  name: string;
  arguments: Record<string, unknown>;
  /// Opaque, provider-specific token (Gemini 3.x's "thought signature") that
  /// must ride along with this call, unread and unmodified, from the moment
  /// it is emitted to the moment its turn is replayed back to the provider —
  /// including the round trip through the client, which owns the transcript.
  /// A provider without this concept simply never sets it.
  thoughtSignature?: string;
}

export interface AiMessage {
  role: AiRole;
  /// Text of a `user` or `assistant` turn.
  content?: string;
  /// Present on an `assistant` turn that asked for tools.
  toolCalls?: AiToolCall[];
  /// Present on a `tool` turn: which call it answers, and with what.
  toolCallId?: string;
  name?: string;
  result?: unknown;
}

// A JSON Schema subset both providers accept. Deliberately loose here; the real
// constraint lives in `tools.ts`, which only ever emits OpenAPI-3.0-compatible
// schemas (no $ref, no oneOf, no additionalProperties — Gemini rejects those).
export type JsonSchema = Record<string, unknown>;

export interface AiToolDef {
  name: string;
  description: string;
  parameters: JsonSchema;
}

export type AiToolMode = 'auto' | 'none' | 'required';

export interface AiRequest {
  system: string;
  messages: AiMessage[];
  tools: AiToolDef[];
  toolMode: AiToolMode;
  temperature?: number;
  maxOutputTokens?: number;
  timeoutMs: number;
}

export type AiFinishReason =
  | 'stop'
  | 'tool_calls'
  | 'length'
  | 'safety'
  | 'other';

export interface AiUsage {
  promptTokens: number;
  completionTokens: number;
}

export interface AiResult {
  text: string;
  toolCalls: AiToolCall[];
  usage: AiUsage;
  finish: AiFinishReason;
}

export type AiProviderErrorKind =
  | 'rate_limited'
  | 'unavailable'
  | 'timeout'
  | 'bad_response'
  | 'auth';

export class AiProviderError extends Error {
  constructor(
    readonly kind: AiProviderErrorKind,
    message: string,
    readonly retryAfterSeconds?: number,
    /// A short, safe-to-log fragment — the upstream HTTP status, never a
    /// piece of the response body. `kind` alone collapsed every non-5xx,
    /// non-401/403/429 failure into a single `bad_response` bucket in
    /// `ai_usage_log.error_code`, with the actual status (a 400? a 404 from a
    /// renamed model?) surviving only in `message`, which nothing persists.
    /// This is the field that lets `error_code` say `bad_response:404`
    /// instead of just `bad_response`.
    readonly detail?: string,
  ) {
    super(message);
    this.name = 'AiProviderError';
  }
}
