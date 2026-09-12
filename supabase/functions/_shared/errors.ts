// Error codes shared by the AI functions and the Flutter client.
//
// `delete-account` answers with a bare `{error: string}`. This family uses a
// typed object instead — `{error: {code, message, retryAfterSeconds?}}` —
// because the app branches its UI on the code: a closed gate, an exhausted
// quota and an unreachable provider are three different screens, and parsing
// them out of a prose string would be guesswork.
//
// Keep these strings in sync with `AiFailureCode` on the Dart side. They are a
// wire contract: renaming one silently changes what the app shows.

export type AiErrorCode =
  | 'invalid_request'
  | 'unauthenticated'
  | 'ai_not_enabled'
  | 'payload_too_large'
  | 'unsupported_protocol'
  | 'quota_exceeded'
  | 'provider_rate_limited'
  | 'provider_unavailable'
  | 'provider_timeout'
  | 'internal';

const STATUS_BY_CODE: Record<AiErrorCode, number> = {
  invalid_request: 400,
  unauthenticated: 401,
  ai_not_enabled: 403,
  payload_too_large: 413,
  unsupported_protocol: 426,
  quota_exceeded: 429,
  provider_rate_limited: 429,
  provider_unavailable: 502,
  provider_timeout: 504,
  internal: 500,
};

export function statusForCode(code: AiErrorCode): number {
  return STATUS_BY_CODE[code] ?? 500;
}

/// An error that already knows how it should reach the client. Anything else
/// thrown inside a handler becomes `internal` with a generic message, so an
/// unexpected stack trace never leaks provider details or a snippet of the
/// user's data.
export class AiHttpError extends Error {
  constructor(
    readonly code: AiErrorCode,
    message: string,
    readonly retryAfterSeconds?: number,
  ) {
    super(message);
    this.name = 'AiHttpError';
  }
}
