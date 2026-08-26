import { AiRequest, AiResult } from './types.ts';

export interface AiProvider {
  /// Stable identifier written to `ai_usage_log.provider`.
  readonly id: string;
  readonly model: string;

  generate(request: AiRequest): Promise<AiResult>;

  // Streaming is intentionally absent in Fase A: the Dart SDK's
  // `functions.invoke` materialises the response body, so consuming a stream
  // would mean dropping to raw `http` and hand-rolling the JWT and the error
  // mapping the client already shares with `delete-account`. The signature is
  // named here so adding it later is an implementation, not a redesign:
  //
  //   stream?(request: AiRequest): AsyncIterable<AiDelta>;
}
