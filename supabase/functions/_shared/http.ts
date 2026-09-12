// Small HTTP helpers shared by the AI functions.

import { AiErrorCode, AiHttpError, statusForCode } from './errors.ts';

const JSON_HEADERS = { 'Content-Type': 'application/json' };

/// Hard ceiling on a request body. The client prunes its transcript well below
/// this (see the `messages`/`snapshot` caps in the Dart side), so hitting it
/// means either a bug or someone poking at the endpoint by hand. Reading the
/// body before checking the size would defeat the purpose, hence the
/// Content-Length check up front plus the byte check after reading — a chunked
/// request has no Content-Length to trust.
export const MAX_BODY_BYTES = 128 * 1024;

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

export function errorResponse(
  code: AiErrorCode,
  message: string,
  retryAfterSeconds?: number,
): Response {
  const payload: Record<string, unknown> = { code, message };
  if (retryAfterSeconds !== undefined) {
    payload.retryAfterSeconds = retryAfterSeconds;
  }
  const headers: Record<string, string> = { ...JSON_HEADERS };
  if (retryAfterSeconds !== undefined) {
    headers['Retry-After'] = String(Math.ceil(retryAfterSeconds));
  }
  return new Response(JSON.stringify({ error: payload }), {
    status: statusForCode(code),
    headers,
  });
}

/// Turns anything a handler threw into a response. Only `AiHttpError` keeps its
/// message; everything else is flattened to a generic `internal` so an
/// exception text — which may quote the provider's payload or the user's own
/// data — never reaches the client. The detail still goes to the function logs.
export function responseForThrown(error: unknown): Response {
  if (error instanceof AiHttpError) {
    return errorResponse(error.code, error.message, error.retryAfterSeconds);
  }
  console.error('unhandled error', error);
  return errorResponse('internal', 'unexpected error');
}

/// Reads and parses a JSON body, enforcing [MAX_BODY_BYTES].
export async function readJsonBody(req: Request): Promise<unknown> {
  const declared = req.headers.get('content-length');
  if (declared && Number(declared) > MAX_BODY_BYTES) {
    throw new AiHttpError('payload_too_large', 'request body too large');
  }

  const raw = await req.arrayBuffer();
  if (raw.byteLength > MAX_BODY_BYTES) {
    throw new AiHttpError('payload_too_large', 'request body too large');
  }

  try {
    return JSON.parse(new TextDecoder().decode(raw));
  } catch (_) {
    throw new AiHttpError('invalid_request', 'body is not valid JSON');
  }
}
