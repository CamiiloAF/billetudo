import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:billetudo/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/domain/entities/ai_tool_call.dart';
import 'package:billetudo/features/ai/domain/entities/ai_turn.dart';
import 'package:billetudo/features/ai/domain/entities/financial_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../ai_fixtures.dart';

class MockAiRemoteDatasource extends Mock implements AiRemoteDatasource {}

/// Records what would have been uploaded, so a test can assert that no
/// conversation content ever reaches the crash reporter.
class RecordingCrashReporter implements CrashReporter {
  final List<Object> errors = <Object>[];
  final List<Failure> failures = <Failure>[];
  final List<String> contexts = <String>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    errors.add(error);
    if (context != null) {
      contexts.add(context);
    }
  }

  @override
  Future<void> recordFailure(Failure failure, {String? context}) async {
    failures.add(failure);
  }

  @override
  Future<void> init() async {}

  @override
  void log(String message, {String? category}) {}

  @override
  Future<void> setUser(String id) async {}

  @override
  Future<void> clearUser() async {}
}

/// The wire half of the assistant: the request document, the response parse
/// and — the part the UI branches on — the error-code table of
/// `supabase/functions/README.md`.
void main() {
  late MockAiRemoteDatasource remote;
  late RecordingCrashReporter crash;
  late AiRepositoryImpl repository;

  AiTurnRequest request({
    FinancialSnapshot? snapshot,
    List<AiMessage>? messages,
    List<AiToolResult> toolResults = const <AiToolResult>[],
  }) =>
      AiTurnRequest(
        conversationId: 'conv-1',
        locale: 'es-CO',
        timezone: 'America/Bogota',
        clientVersion: '1.12.0+134',
        messages: messages ??
            [
              buildAiMessage(
                id: 'm1',
                role: AiMessageRole.user,
                content: '¿en qué se me fue la plata?',
              ),
            ],
        snapshot: snapshot,
        toolResults: toolResults,
      );

  Future<Map<String, Object?>> capturedBody() async {
    await repository.sendTurn(request());
    return verify(() => remote.sendTurn(captureAny())).captured.single
        as Map<String, Object?>;
  }

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    remote = MockAiRemoteDatasource();
    crash = RecordingCrashReporter();
    repository = AiRepositoryImpl(remote, crash);
  });

  group('request document', () {
    test('carries the protocol version the function will check', () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      final body = await capturedBody();

      expect(body['protocolVersion'], AiRepositoryImpl.protocolVersion);
      expect(body['conversationId'], 'conv-1');
      expect(body['locale'], 'es-CO');
      expect(body['timezone'], 'America/Bogota');
      expect(body['clientVersion'], '1.12.0+134');
    });

    test('a snapshot that could not be built travels as an empty object, not '
        'as a missing key', () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      final body = await capturedBody();

      expect(body.containsKey('snapshot'), isTrue);
      expect(body['snapshot'], isEmpty);
    });

    test('a built snapshot travels as its own json', () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});
      final snapshot = FinancialSnapshot(
        generatedAt: DateTime(2026, 8, 25),
        periodStart: DateTime(2026, 8),
        periodEndExclusive: DateTime(2026, 9),
        accounts: const [],
      );

      await repository.sendTurn(request(snapshot: snapshot));

      final body = verify(() => remote.sendTurn(captureAny())).captured.single
          as Map<String, Object?>;
      expect(body['snapshot'], snapshot.toJson());
    });

    test('never sends a user id: the function resolves it from the JWT',
        () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      final body = await capturedBody();

      expect(body.containsKey('userId'), isFalse);
      expect(body.containsKey('user_id'), isFalse);
    });

    test('a tool answer is preceded by the assistant turn that asked for it',
        () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      await repository.sendTurn(
        request(
          toolResults: const [
            AiToolResult(
              toolCallId: 'tc_0_0',
              name: 'get_category_breakdown',
              result: <String, Object?>{'totalMinor': 284000000},
            ),
          ],
        ),
      );

      final body = verify(() => remote.sendTurn(captureAny())).captured.single
          as Map<String, Object?>;
      final messages = body['messages']! as List;
      expect(messages, hasLength(3));
      expect((messages[0]! as Map<String, Object?>)['role'], 'user');
      expect((messages[1]! as Map<String, Object?>)['role'], 'assistant');
      expect(
        ((messages[1]! as Map<String, Object?>)['toolCalls']! as List).single,
        containsPair('name', 'get_category_breakdown'),
      );
      expect((messages[2]! as Map<String, Object?>)['role'], 'tool');
      expect(
        (messages[2]! as Map<String, Object?>)['result'],
        <String, Object?>{'totalMinor': 284000000},
      );
    });

    test(
        'a thoughtSignature carried on the result rides back on the rebuilt '
        'assistant turn, unread', () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      await repository.sendTurn(
        request(
          toolResults: const [
            AiToolResult(
              toolCallId: 'tc_0_0',
              name: 'get_category_breakdown',
              result: <String, Object?>{'totalMinor': 284000000},
              thoughtSignature: 'opaque-signature-abc',
            ),
          ],
        ),
      );

      final body = verify(() => remote.sendTurn(captureAny())).captured.single
          as Map<String, Object?>;
      final messages = body['messages']! as List;
      final rebuiltCall =
          ((messages[1]! as Map<String, Object?>)['toolCalls']! as List)
              .single as Map<String, Object?>;
      expect(rebuiltCall['thoughtSignature'], 'opaque-signature-abc');
    });

    test('a tool result with no thoughtSignature omits the key rather than '
        'sending it as null', () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{});

      await repository.sendTurn(
        request(
          toolResults: const [
            AiToolResult(
              toolCallId: 'tc_0_0',
              name: 'get_category_breakdown',
              result: <String, Object?>{'totalMinor': 284000000},
            ),
          ],
        ),
      );

      final body = verify(() => remote.sendTurn(captureAny())).captured.single
          as Map<String, Object?>;
      final messages = body['messages']! as List;
      final rebuiltCall =
          ((messages[1]! as Map<String, Object?>)['toolCalls']! as List)
              .single as Map<String, Object?>;
      expect(rebuiltCall.containsKey('thoughtSignature'), isFalse);
    });
  });

  group('response parse', () {
    test('reads the bubble text, its proposals and the finish reason',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'message',
          'message': <String, Object?>{
            'role': 'assistant',
            'content': 'Gastaste menos este mes.',
            'proposals': <Object?>[
              <String, Object?>{
                'id': 'tc_0_0',
                'kind': 'create_budget',
                'title': 'Un presupuesto para Comida',
                'payload': <String, Object?>{
                  'name': 'Comida',
                  'amountMinor': 45000000,
                  'currency': 'COP',
                  'period': 'monthly',
                },
              },
            ],
          },
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.finishReason, AiFinishReason.message);
      expect(response.content, 'Gastaste menos este mes.');
      expect(response.proposals.single, isA<CreateBudgetProposal>());
      expect(response.needsToolResolution, isFalse);
    });

    test('an unknown finish reason still shows the text the model sent',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'something_new',
          'message': <String, Object?>{'content': 'Hola'},
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.finishReason, AiFinishReason.message);
      expect(response.content, 'Hola');
    });

    test('a proposal kind this build cannot execute is kept, never dropped',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'message',
          'message': <String, Object?>{
            'content': 'Mirá esto',
            'proposals': <Object?>[
              <String, Object?>{
                'id': 'tc_0_9',
                'kind': 'create_spaceship',
                'title': 'Comprar una nave',
              },
            ],
          },
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(
        response.proposals.single,
        isA<UnsupportedProposal>()
            .having((p) => p.rawKind, 'rawKind', 'create_spaceship'),
      );
    });

    test('tool calls are read and the turn is flagged as needing resolution',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'tool_calls',
          'message': <String, Object?>{'content': ''},
          'toolCalls': <Object?>[
            <String, Object?>{
              'id': 'tc_0_0',
              'name': 'get_transactions',
              'arguments': <String, Object?>{'from': 1754006400},
            },
            // No name: unaddressable, so it is skipped rather than guessed.
            <String, Object?>{'id': 'tc_0_1'},
          ],
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.finishReason, AiFinishReason.toolCalls);
      expect(response.needsToolResolution, isTrue);
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls.single.arguments, {'from': 1754006400});
    });

    test('a tool call with no id falls back to its name so it stays '
        'addressable', () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'tool_calls',
          'message': <String, Object?>{'content': ''},
          'toolCalls': <Object?>[
            <String, Object?>{'name': 'get_goal_detail'},
          ],
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.toolCalls.single.id, 'get_goal_detail');
    });

    test('a thoughtSignature on a tool call is read from the response',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'tool_calls',
          'message': <String, Object?>{'content': ''},
          'toolCalls': <Object?>[
            <String, Object?>{
              'id': 'tc_0_0',
              'name': 'get_transactions',
              'arguments': <String, Object?>{},
              'thoughtSignature': 'opaque-signature-abc',
            },
          ],
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(
        response.toolCalls.single.thoughtSignature,
        'opaque-signature-abc',
      );
    });

    test('a tool call with no thoughtSignature parses to null, not a crash',
        () async {
      when(() => remote.sendTurn(any())).thenAnswer(
        (_) async => <String, Object?>{
          'finishReason': 'tool_calls',
          'message': <String, Object?>{'content': ''},
          'toolCalls': <Object?>[
            <String, Object?>{
              'id': 'tc_0_0',
              'name': 'get_transactions',
              'arguments': <String, Object?>{},
            },
          ],
        },
      );

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.toolCalls.single.thoughtSignature, isNull);
    });

    test('a response with no message at all parses to an empty bubble',
        () async {
      when(() => remote.sendTurn(any()))
          .thenAnswer((_) async => <String, Object?>{'finishReason': 'blocked'});

      final response = (await repository.sendTurn(request()))
          .getRight()
          .toNullable()!;

      expect(response.finishReason, AiFinishReason.blocked);
      expect(response.content, '');
      expect(response.proposals, isEmpty);
      expect(response.toolCalls, isEmpty);
    });
  });

  group('error code table', () {
    final codes = <String, (int, AiFailureCode)>{
      'invalid_request': (400, AiFailureCode.invalidRequest),
      'unauthenticated': (401, AiFailureCode.unauthenticated),
      'ai_not_enabled': (403, AiFailureCode.aiNotEnabled),
      'payload_too_large': (413, AiFailureCode.payloadTooLarge),
      'unsupported_protocol': (426, AiFailureCode.unsupportedProtocol),
      'quota_exceeded': (429, AiFailureCode.quotaExceeded),
      'provider_rate_limited': (429, AiFailureCode.providerRateLimited),
      'provider_unavailable': (502, AiFailureCode.providerUnavailable),
      'provider_timeout': (504, AiFailureCode.providerTimeout),
      'internal': (500, AiFailureCode.internal),
    };

    codes.forEach((wireCode, expected) {
      test('$wireCode becomes ${expected.$2.name} so the UI can branch on it',
          () async {
        when(() => remote.sendTurn(any())).thenThrow(
          AiRemoteException(
            status: expected.$1,
            payload: <String, Object?>{
              'error': <String, Object?>{
                'code': wireCode,
                'message': 'server prose',
              },
            },
          ),
        );

        final result = await repository.sendTurn(request());

        expect(
          result.getLeft().toNullable(),
          isA<AiFailure>().having((f) => f.code, 'code', expected.$2),
        );
      });
    });

    test('a code this build does not know still reads as an AiFailure',
        () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 418,
          payload: <String, Object?>{
            'error': <String, Object?>{'code': 'teapot'},
          },
        ),
      );

      final result = await repository.sendTurn(request());

      expect(
        result.getLeft().toNullable(),
        isA<AiFailure>().having((f) => f.code, 'code', AiFailureCode.unknown),
      );
    });

    test('a bare status with no body still maps by HTTP status', () async {
      when(() => remote.sendTurn(any()))
          .thenThrow(const AiRemoteException(status: 401));

      final result = await repository.sendTurn(request());

      expect(
        result.getLeft().toNullable(),
        isA<AiFailure>()
            .having((f) => f.code, 'code', AiFailureCode.unauthenticated),
      );
    });

    test('a call the server never answered is a NetworkFailure, so the UI '
        'offers a retry instead of hiding the assistant', () async {
      when(() => remote.sendTurn(any())).thenThrow(
        AiRemoteException(cause: Exception('socket closed')),
      );

      final result = await repository.sendTurn(request());

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('provider_rate_limited keeps the retry delay the server asked for',
        () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 429,
          payload: <String, Object?>{
            'error': <String, Object?>{
              'code': 'provider_rate_limited',
              'retryAfterSeconds': 30,
            },
          },
        ),
      );

      final result = await repository.sendTurn(request());

      expect(
        result.getLeft().toNullable(),
        isA<AiFailure>()
            .having((f) => f.retryAfterSeconds, 'retryAfterSeconds', 30),
      );
    });

    test('a retry delay sent as a string is still read', () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 429,
          payload: <String, Object?>{
            'error': <String, Object?>{
              'code': 'provider_rate_limited',
              'retryAfterSeconds': '45',
            },
          },
        ),
      );

      final result = await repository.sendTurn(request());

      expect(
        (result.getLeft().toNullable()! as AiFailure).retryAfterSeconds,
        45,
      );
    });

    test('only the codes that mean a bug are reported to the crash reporter',
        () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 403,
          payload: <String, Object?>{
            'error': <String, Object?>{'code': 'ai_not_enabled'},
          },
        ),
      );
      await repository.sendTurn(request());
      expect(crash.errors, isEmpty);

      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 500,
          payload: <String, Object?>{
            'error': <String, Object?>{'code': 'internal'},
          },
        ),
      );
      await repository.sendTurn(request());

      expect(crash.errors, hasLength(1));
      expect(crash.contexts, ['ai-chat']);
    });

    test(
        'unauthenticated is reported too: the composer is gated on a live '
        'session, so a 401 that still reaches here means the token expired '
        'mid-conversation, not an expected operating condition', () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 401,
          payload: <String, Object?>{
            'error': <String, Object?>{'code': 'unauthenticated'},
          },
        ),
      );
      await repository.sendTurn(request());

      expect(crash.errors, hasLength(1));
      expect(crash.contexts, ['ai-chat']);
    });
  });

  group('privacy', () {
    test('the failure message is built from the code and status only, never '
        'from the server prose', () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 400,
          payload: <String, Object?>{
            'error': <String, Object?>{
              'code': 'invalid_request',
              'message': 'snapshot.accounts[0].name "Cuenta de Ana" is invalid',
            },
          },
        ),
      );

      final result = await repository.sendTurn(request());

      final failure = result.getLeft().toNullable()!;
      expect(failure.message, isNot(contains('Cuenta de Ana')));
      expect(failure.message, contains(AiFailureCode.invalidRequest.name));
      expect(failure.message, contains('400'));
    });

    test('what reaches the crash reporter names the code, not the prose',
        () async {
      when(() => remote.sendTurn(any())).thenThrow(
        const AiRemoteException(
          status: 400,
          payload: <String, Object?>{
            'error': <String, Object?>{
              'code': 'invalid_request',
              'message': 'the user said "me gasté la plata en el bar"',
            },
          },
        ),
      );

      await repository.sendTurn(request());

      expect(crash.errors.single.toString(), isNot(contains('el bar')));
      expect(
        crash.errors.single.toString(),
        contains(AiFailureCode.invalidRequest.name),
      );
    });
  });

  group('checkAccess', () {
    test('no row at all is denied, never allowed', () async {
      when(remote.checkAccess).thenAnswer((_) async => null);

      final access =
          (await repository.checkAccess()).getRight().toNullable()!;

      expect(access.allowed, isFalse);
      expect(access.remainingToday, isNull);
    });

    test('an enabled gate with a quota reports what is left today', () async {
      when(remote.checkAccess).thenAnswer(
        (_) async => <String, Object?>{
          'enabled': true,
          'daily_message_limit': 20,
          'used_today': 8,
        },
      );

      final access =
          (await repository.checkAccess()).getRight().toNullable()!;

      expect(access.allowed, isTrue);
      expect(access.remainingToday, 12);
    });

    test('a spent quota counts down to zero, not below', () async {
      when(remote.checkAccess).thenAnswer(
        (_) async => <String, Object?>{
          'enabled': true,
          'daily_message_limit': 5,
          'used_today': 9,
        },
      );

      final access =
          (await repository.checkAccess()).getRight().toNullable()!;

      expect(access.remainingToday, 0);
    });

    test('no quota configured means "not measured", not "zero left"', () async {
      when(remote.checkAccess).thenAnswer(
        (_) async => <String, Object?>{
          'enabled': true,
          'daily_message_limit': 0,
          'used_today': 3,
        },
      );

      final access =
          (await repository.checkAccess()).getRight().toNullable()!;

      expect(access.remainingToday, isNull);
    });

    test('the beta tier is the only one that earns a badge', () async {
      when(remote.checkAccess).thenAnswer(
        (_) async => <String, Object?>{'enabled': true, 'tier': 'beta'},
      );
      final beta = (await repository.checkAccess()).getRight().toNullable()!;

      when(remote.checkAccess).thenAnswer(
        (_) async => <String, Object?>{'enabled': true, 'tier': 'premium'},
      );
      final premium = (await repository.checkAccess()).getRight().toNullable()!;

      expect(beta.isBeta, isTrue);
      expect(beta.betaLabel, 'Beta');
      expect(premium.isBeta, isFalse);
    });

    test('a gate that could not be read fails as a Left, not as a silent '
        'denial', () async {
      when(remote.checkAccess).thenThrow(
        AiRemoteException(cause: Exception('no signal')),
      );

      final result = await repository.checkAccess();

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('an unauthenticated gate is distinguishable from an unreachable one',
        () async {
      when(remote.checkAccess).thenThrow(
        const AiRemoteException(
          status: 401,
          payload: 'JWT expired',
        ),
      );

      final result = await repository.checkAccess();

      expect(
        result.getLeft().toNullable(),
        isA<AiFailure>()
            .having((f) => f.code, 'code', AiFailureCode.unauthenticated),
      );
    });
  });
}
