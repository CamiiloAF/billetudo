import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/data/datasources/ai_report_remote_datasource.dart';
import 'package:billetudo/features/ai/data/repositories/ai_report_repository_impl.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiReportRemoteDatasource extends Mock
    implements AiReportRemoteDatasource {}

/// A rejected insert as Postgres reports it: the offending row, and with it
/// the reported message, inside the exception text.
class FakePostgresException implements Exception {
  const FakePostgresException();

  @override
  String toString() =>
      'PostgrestException(message: new row violates check constraint, '
      'details: Failing row contains (…, me gasté la plata en el bar, …))';
}

/// Reporting is the single exception to "nothing from a conversation reaches a
/// server": the text travels because the person asked for it to. That makes it
/// the one place where an error must NOT carry the same text anywhere else.
void main() {
  late MockAiReportRemoteDatasource remote;
  late AiReportRepositoryImpl repository;

  const report = AiReport(
    reason: AiReportReason.wrong,
    reportedText: 'me gasté la plata en el bar',
    clientVersion: '1.12.0+134',
    conversationId: 'conv-1',
    comment: 'la cifra no cuadra',
  );

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    remote = MockAiReportRemoteDatasource();
    repository = AiReportRepositoryImpl(remote);
  });

  group('filing a report', () {
    test('writes the closed-list reason and the single reported message',
        () async {
      when(() => remote.insertReport(any())).thenAnswer((_) async {});

      final result = await repository.report(report);

      expect(result.isRight(), isTrue);
      final row = verify(() => remote.insertReport(captureAny()))
          .captured
          .single as Map<String, Object?>;
      expect(row['reason'], 'wrong');
      expect(row['reported_text'], 'me gasté la plata en el bar');
      expect(row['comment'], 'la cifra no cuadra');
      expect(row['conversation_id'], 'conv-1');
      expect(row['client_version'], '1.12.0+134');
    });

    test('never writes the moderation status, which only the backend owns',
        () async {
      when(() => remote.insertReport(any())).thenAnswer((_) async {});

      await repository.report(report);

      final row = verify(() => remote.insertReport(captureAny()))
          .captured
          .single as Map<String, Object?>;
      expect(row.containsKey('status'), isFalse);
      expect(row.containsKey('user_id'), isFalse);
    });

    test('a report without a comment or a conversation still files', () async {
      when(() => remote.insertReport(any())).thenAnswer((_) async {});

      await repository.report(
        const AiReport(
          reason: AiReportReason.offensive,
          reportedText: 'texto reportado',
          clientVersion: '1.12.0+134',
        ),
      );

      final row = verify(() => remote.insertReport(captureAny()))
          .captured
          .single as Map<String, Object?>;
      expect(row['comment'], isNull);
      expect(row['conversation_id'], isNull);
      expect(row['reason'], 'offensive');
    });
  });

  group('failures', () {
    test(
        'a session-less report is phrased as an auth problem, not as a '
        'network one', () async {
      when(() => remote.insertReport(any()))
          .thenThrow(const AiReportException(isUnauthenticated: true));

      final result = await repository.report(report);

      expect(
        result.getLeft().toNullable(),
        isA<AiFailure>()
            .having((f) => f.code, 'code', AiFailureCode.unauthenticated),
      );
    });

    test('anything else earns a retry, as a NetworkFailure', () async {
      when(() => remote.insertReport(any())).thenThrow(
        const AiReportException(
          isUnauthenticated: false,
          cause: FakePostgresException(),
        ),
      );

      final result = await repository.report(report);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('privacy', () {
    test('the reported text never travels inside the failure cause', () async {
      when(() => remote.insertReport(any())).thenThrow(
        const AiReportException(
          isUnauthenticated: false,
          cause: FakePostgresException(),
        ),
      );

      final failure = (await repository.report(report)).getLeft().toNullable()!;

      expect(failure.cause.toString(), isNot(contains('el bar')));
      expect(failure.cause.toString(), isNot(contains('Failing row')));
      expect(failure.cause.toString(), contains('FakePostgresException'));
      expect(failure.message, isNot(contains('el bar')));
    });

    test('the same stripping applies to the unauthenticated branch', () async {
      when(() => remote.insertReport(any())).thenThrow(
        const AiReportException(
          isUnauthenticated: true,
          cause: FakePostgresException(),
        ),
      );

      final failure = (await repository.report(report)).getLeft().toNullable()!;

      expect(failure.cause.toString(), isNot(contains('el bar')));
    });

    test('a failure with no cause at all keeps none', () async {
      when(() => remote.insertReport(any()))
          .thenThrow(const AiReportException(isUnauthenticated: false));

      final failure = (await repository.report(report)).getLeft().toNullable()!;

      expect(failure.cause, isNull);
    });
  });
}
