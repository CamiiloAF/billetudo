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
  ) {
    super(message);
    this.name = 'AiProviderError';
  }
}
