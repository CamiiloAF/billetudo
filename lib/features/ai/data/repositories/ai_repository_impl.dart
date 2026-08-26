import 'dart:math' as math;

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/ai_access.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/ai_tool_call.dart';
import '../../domain/entities/ai_turn.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../mappers/ai_action_proposal_mapper.dart';

/// The wire half of the assistant: it owns the protocol version, the request
/// document, the response parse, and the error-code → `Failure` table.
///
/// Nothing is cached. The function is stateless by design and the gate is a
/// server-side quota — a cached verdict on one of those is exactly the
/// client-side limit `CLAUDE.md` forbids.
@LazySingleton(as: AiRepository)
class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._remote, this._crash);

  final AiRemoteDatasource _remote;
  final CrashReporter _crash;

  /// Must match `PROTOCOL_VERSION` in `supabase/functions/_shared/ai/
  /// validate.ts`. A mismatch is answered with `426 unsupported_protocol`,
  /// which is how "actualizá la app" becomes possible at all.
  static const int protocolVersion = 1;

  @override
  FutureResult<AiTurnResponse> sendTurn(AiTurnRequest request) async {
    try {
      final data = await _remote.sendTurn(_requestBody(request));
      return Right(_parseResponse(data));
    } on AiRemoteException catch (e) {
      return Left(await _mapRemoteFailure(e));
    }
  }

  @override
  FutureResult<AiAccess> checkAccess() async {
    try {
      final row = await _remote.checkAccess();
      // No row is not an error: the RPC is granted to `authenticated` only, so
      // a device with no session simply has no gate to read. Denied, quietly.
      if (row == null) {
        return const Right(AiAccess.denied);
      }
      return Right(_parseAccess(row));
    } on AiRemoteException catch (e) {
      // Fails closed by contract, but as a `Left` rather than a silent
      // `AiAccess.denied`: presentation must be able to tell "the assistant is
      // not for you" from "we could not ask", and offer a retry for the
      // second. Both hide the entry point.
      return Left(await _mapRemoteFailure(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Request
  // ---------------------------------------------------------------------------

  Map<String, Object?> _requestBody(AiTurnRequest request) => <String, Object?>{
        'protocolVersion': protocolVersion,
        'conversationId': request.conversationId,
        'locale': request.locale,
        'timezone': request.timezone,
        'clientVersion': request.clientVersion,
        // The function rejects a missing or non-object `snapshot` with `400
        // invalid_request`, so a snapshot that could not be built travels as
        // `{}` rather than being omitted. That is still honest: an empty
        // object asserts nothing, and the snapshot's own rule — a section that
        // could not be read is dropped, never sent empty — degrades to exactly
        // this when *no* section could be read.
        'snapshot': request.snapshot?.toJson() ?? const <String, Object?>{},
        'messages': _messages(request),
      };

  List<Map<String, Object?>> _messages(AiTurnRequest request) {
    final messages = <Map<String, Object?>>[
      for (final message in request.messages)
        <String, Object?>{
          'role': switch (message.role) {
            AiMessageRole.user => 'user',
            AiMessageRole.assistant => 'assistant',
          },
          'content': message.content,
        },
    ];

    if (request.toolResults.isEmpty) {
      return messages;
    }

    // A `role: "tool"` message is only legible to the provider when the model
    // turn that asked for it precedes it (Gemini matches a `functionResponse`
    // to its `functionCall`). That assistant turn is never a bubble and is
    // never persisted, so it is rebuilt here from the results themselves.
    //
    // Known gap: `AiToolResult` carries no copy of the original `arguments`,
    // so the rebuilt call goes out with `{}`. Matching still works — Gemini
    // pairs by name — but the model loses sight of the exact window it asked
    // for. Carrying the arguments on the result would close it.
    messages
      ..add(<String, Object?>{
        'role': 'assistant',
        'content': '',
        'toolCalls': <Map<String, Object?>>[
          for (final result in request.toolResults)
            <String, Object?>{
              'id': result.toolCallId,
              'name': result.name,
              'arguments': const <String, Object?>{},
              // Gemini 3.x rejects a replayed function call missing this
              // token, so it must ride back unread — see `AiToolCall.
              // thoughtSignature`. Omitted, not `null`, when the provider
              // never set one.
              if (result.thoughtSignature != null)
                'thoughtSignature': result.thoughtSignature,
            },
        ],
      })
      ..addAll(<Map<String, Object?>>[
        for (final result in request.toolResults)
          <String, Object?>{
            'role': 'tool',
            'toolCallId': result.toolCallId,
            'name': result.name,
            'content': null,
            'result': result.result,
          },
      ]);

    return messages;
  }

  // ---------------------------------------------------------------------------
  // Response
  // ---------------------------------------------------------------------------

  AiTurnResponse _parseResponse(Map<String, Object?> data) {
    final message = _asMap(data['message']) ?? const <String, Object?>{};
    final finishReason = _finishReason(data['finishReason']);
    final toolCalls = _toolCalls(data['toolCalls']);

    return AiTurnResponse(
      finishReason: finishReason,
      content: switch (message['content']) {
        final String content => content,
        _ => '',
      },
      proposals: AiActionProposalMapper.fromJsonList(message['proposals']),
      toolCalls: toolCalls,
    );
  }

  /// An unknown reason reads as [AiFinishReason.message]: the text that came
  /// with it is still shown, and the app simply does not act on a reason it
  /// cannot name — the same degrade-don't-throw rule the proposals follow.
  AiFinishReason _finishReason(Object? raw) => switch (raw) {
        'tool_calls' => AiFinishReason.toolCalls,
        'max_iterations' => AiFinishReason.maxIterations,
        'blocked' => AiFinishReason.blocked,
        _ => AiFinishReason.message,
      };

  List<AiToolCall> _toolCalls(Object? raw) {
    if (raw is! List) {
      return const <AiToolCall>[];
    }
    return <AiToolCall>[
      for (final item in raw)
        if (_asMap(item) case final Map<String, Object?> call)
          if (call['name'] case final String name when name.isNotEmpty)
            AiToolCall(
              id: switch (call['id']) {
                final String id => id,
                _ => name,
              },
              name: name,
              arguments: _asMap(call['arguments']) ?? const <String, Object?>{},
              thoughtSignature: switch (call['thoughtSignature']) {
                final String signature => signature,
                _ => null,
              },
            ),
    ];
  }

  AiAccess _parseAccess(Map<String, Object?> row) {
    final limit = _int(row['daily_message_limit']);
    final used = _int(row['used_today']) ?? 0;
    final tier = switch (row['tier']) {
      final String tier => tier,
      _ => null,
    };

    return AiAccess(
      allowed: row['enabled'] == true,
      // `reason` is deliberately left unset: the RPC returns no explanation
      // string (the gate it reads is a boolean plus a quota), and every
      // localized reason the entity documents would have to come from the Edge
      // Function instead. A made-up reason is worse than none.
      //
      // 'Beta' is the same word in both supported locales, which is why this
      // one label can be decided client-side without breaking the entity's
      // "backend-localized" rule. Any other tier gets no badge.
      betaLabel: tier == 'beta' ? 'Beta' : null,
      // `null` means *not measured*, not zero. A non-positive limit is how the
      // server says "no quota here" (Fase A), and counting down from it would
      // show a phantom "0 mensajes restantes".
      remainingToday:
          limit == null || limit <= 0 ? null : math.max(0, limit - used),
    );
  }

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  /// Maps the `{"error": {"code", "message", "retryAfterSeconds"?}}` envelope
  /// to a `Failure`, per the table in `supabase/functions/README.md`.
  ///
  /// A structured code always becomes an `AiFailure`, because the app branches
  /// on several of them (prune and resend, go to the store, wait N seconds,
  /// hide the entry point). Only a call the server never answered becomes a
  /// `NetworkFailure` — there is no code to branch on and nothing to say but
  /// "reintentá".
  ///
  /// **Nothing user-authored travels into [Failure.message] or into Sentry.**
  /// The server's prose is dropped and only the code plus the HTTP status are
  /// kept: the request body held the transcript and the financial snapshot,
  /// and the privacy policy promises neither is retained on any server —
  /// Sentry is a server.
  Future<Failure> _mapRemoteFailure(AiRemoteException e) async {
    final envelope = _asMap(_asMap(e.payload)?['error']);
    final code = _failureCode(envelope?['code'], e.status);

    if (code == null) {
      return NetworkFailure(
        'ai-chat unreachable (no response)',
        cause: _sanitize(e.cause),
        stackTrace: e.stackTrace,
      );
    }

    // The two codes the README marks as bugs, plus `unauthenticated`: the
    // presentation layer gates the composer on `WatchAuthSession` before this
    // repository is ever called (`AiChatCubit`/`AiSignedOutPage`), so by the
    // time a request reaches here the caller is expected to have a live
    // session. An `unauthenticated` response past that gate means the token
    // expired mid-conversation or something is wrong with session handling —
    // worth knowing, not an expected operating condition like a closed gate,
    // a spent quota, or a rate limit, which would just bury the real ones.
    if (code == AiFailureCode.invalidRequest ||
        code == AiFailureCode.internal ||
        code == AiFailureCode.unauthenticated) {
      await _crash.recordError(
        StateError('ai-chat returned ${code.name} (HTTP ${e.status})'),
        e.stackTrace,
        context: 'ai-chat',
      );
    }

    return AiFailure(
      'ai-chat returned ${code.name} (HTTP ${e.status})',
      code: code,
      retryAfterSeconds: _int(envelope?['retryAfterSeconds']),
      cause: _sanitize(e.cause),
      stackTrace: e.stackTrace,
    );
  }

  /// Keeps the original error's type and drops everything else.
  ///
  /// The doc above promises the server's prose never reaches Sentry, and
  /// `_mapRemoteFailure` honours that for [Failure.message] — but `cause` was
  /// passing `e.cause` through untouched, and for a `FunctionException` that
  /// object is the whole `{"error": {...}}` envelope. `CrashReporter`
  /// uploads `Failure.cause` verbatim, so a future caller reaching for
  /// `recordFailure` instead of the scrubbed `recordError` below would have
  /// shipped it.
  ///
  /// Today's envelope is server-authored, so nothing the user wrote is at
  /// risk. This is defence in depth against the day an error message starts
  /// echoing back part of the request — and it makes this repository behave
  /// like its two siblings, which already sanitize (`AiReportRepositoryImpl`,
  /// `AiHistoryRepositoryImpl`). A promise honoured in one of three places is
  /// the kind that quietly stops being true.
  Object? _sanitize(Object? error) => error == null
      ? null
      : StateError('ai-chat failed with ${error.runtimeType}');

  /// The wire strings of `AiErrorCode` (`_shared/errors.ts`). Falls back to
  /// the HTTP status when the body is missing or unparseable — a bare 401 from
  /// the platform (an expired JWT never reaching the function) has to read as
  /// [AiFailureCode.unauthenticated] all the same.
  ///
  /// Returns `null` only when there was no response at all.
  AiFailureCode? _failureCode(Object? raw, int? status) => switch (raw) {
        'invalid_request' => AiFailureCode.invalidRequest,
        'unauthenticated' => AiFailureCode.unauthenticated,
        'ai_not_enabled' => AiFailureCode.aiNotEnabled,
        'payload_too_large' => AiFailureCode.payloadTooLarge,
        'unsupported_protocol' => AiFailureCode.unsupportedProtocol,
        'quota_exceeded' => AiFailureCode.quotaExceeded,
        'provider_rate_limited' => AiFailureCode.providerRateLimited,
        'provider_unavailable' => AiFailureCode.providerUnavailable,
        'provider_timeout' => AiFailureCode.providerTimeout,
        'internal' => AiFailureCode.internal,
        _ => switch (status) {
            null => null,
            400 => AiFailureCode.invalidRequest,
            401 => AiFailureCode.unauthenticated,
            403 => AiFailureCode.aiNotEnabled,
            413 => AiFailureCode.payloadTooLarge,
            426 => AiFailureCode.unsupportedProtocol,
            429 => AiFailureCode.providerRateLimited,
            502 => AiFailureCode.providerUnavailable,
            504 => AiFailureCode.providerTimeout,
            500 => AiFailureCode.internal,
            _ => AiFailureCode.unknown,
          },
      };

  static Map<String, Object?>? _asMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return <String, Object?>{
        for (final entry in raw.entries) '${entry.key}': entry.value,
      };
    }
    return null;
  }

  static int? _int(Object? raw) => switch (raw) {
        final int value => value,
        final double value when value.isFinite => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
}
