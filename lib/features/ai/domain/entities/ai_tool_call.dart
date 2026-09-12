import 'package:equatable/equatable.dart';

/// A read the model asked the **app** to perform.
///
/// Read tools never run on the server: Postgres is a mirror that can lag a
/// sync or sit half-merged right after a login, and a model answering from a
/// stale mirror lies with total confidence. Resolving on-device also means the
/// backend never needs read access to a single financial table
/// (`supabase/functions/README.md`, "Herramientas").
class AiToolCall extends Equatable {
  const AiToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.thoughtSignature,
  });

  /// Synthesised by the provider adapter (Gemini has no tool-call ids of its
  /// own). Stable within one turn only — never use it as a persisted key.
  final String id;

  /// One of the five read tools. An unknown name is answered with an `error`
  /// result, not a failure: see `ResolveAiToolCall`.
  final String name;

  /// Raw JSON arguments. Left untyped because the tool schema lives on the
  /// server and grows there first; `ResolveAiToolCall` reads only the keys it
  /// understands and ignores the rest.
  final Map<String, Object?> arguments;

  /// Opaque, provider-specific token (Gemini 3.x's "thought signature") that
  /// must ride along with this call, unread and unmodified, from the moment
  /// it is emitted to the moment its turn is replayed back to the provider —
  /// including the round trip through this client, which owns the transcript.
  /// A provider without this concept simply never sets it.
  final String? thoughtSignature;

  @override
  List<Object?> get props => [id, name, arguments, thoughtSignature];
}

/// The answer to an [AiToolCall], posted back as a `role: "tool"` message.
class AiToolResult extends Equatable {
  const AiToolResult({
    required this.toolCallId,
    required this.name,
    required this.result,
    this.thoughtSignature,
  });

  final String toolCallId;
  final String name;

  /// Always a JSON **object**, never a bare array — Gemini rejects a top-level
  /// array in a function response. A read that could not be resolved carries
  /// `{'error': ..., 'message': ...}` here rather than failing the turn.
  final Map<String, Object?> result;

  /// Copied verbatim from the [AiToolCall] this answers. Carried here (rather
  /// than looked up again) so it can travel forward to the rebuilt
  /// `assistant` turn the next request sends — see `AiRepositoryImpl._messages`.
  final String? thoughtSignature;

  @override
  List<Object?> get props => [toolCallId, name, result, thoughtSignature];
}
