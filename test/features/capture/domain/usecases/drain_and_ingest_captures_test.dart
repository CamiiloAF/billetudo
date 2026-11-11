import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_notification.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/drain_and_ingest_captures.dart';
import 'package:billetudo/features/capture/domain/usecases/drain_native_captures.dart';
import 'package:billetudo/features/capture/domain/usecases/ingest_parsed_captures.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

class MockDrainNativeCaptures extends Mock implements DrainNativeCaptures {}

class MockIngestParsedCaptures extends Mock implements IngestParsedCaptures {}

/// The single path from "the native buffer has something" to "the inbox has
/// rows". It used to be duplicated between bootstrap and the Avisos cubit,
/// which is how a capture could be ingested on cold start but ignored live.
void main() {
  late MockDrainNativeCaptures drain;
  late MockIngestParsedCaptures ingest;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    drain = MockDrainNativeCaptures();
    ingest = MockIngestParsedCaptures();
  });

  DrainAndIngestCaptures build() => DrainAndIngestCaptures(drain, ingest);

  ParsedNotification nativeCapture() => ParsedNotification(
        issuerId: 'nu',
        sourcePackage: 'com.nu.production',
        ruleId: 'nu.purchase',
        amountMinor: 5847000,
        currency: 'COP',
        entryType: TransactionType.expense,
        postedAt: DateTime(2026, 11, 11, 9, 40),
        merchantRaw: 'TIENDA D1 SANTA ROSA',
        accountHint: '5615',
      );

  test('maps the drained notification fields before persisting them',
      () async {
    when(drain.call)
        .thenAnswer(
      (_) async => Right<Failure, List<ParsedNotification>>([nativeCapture()]),
    );
    when(() => ingest(any())).thenAnswer(
      (_) async => const Right<Failure, List<PendingCapture>>(<PendingCapture>[]),
    );

    await build()();

    final List<ParsedCapture> persisted =
        verify(() => ingest(captureAny())).captured.single
            as List<ParsedCapture>;
    expect(persisted, hasLength(1));
    final ParsedCapture capture = persisted.single;
    expect(capture.sourcePackage, 'com.nu.production');
    expect(capture.sourceRuleId, 'nu.purchase');
    expect(capture.amountMinor, 5847000);
    expect(capture.currency, 'COP');
    expect(capture.entryType, TransactionType.expense);
    expect(capture.postedAt, DateTime(2026, 11, 11, 9, 40));
    expect(capture.merchantRaw, 'TIENDA D1 SANTA ROSA');
    expect(capture.accountHint, '5615');
    // A capture is never a movement by itself.
    expect(capture.source, TransactionSource.notification);
  });

  test('an empty buffer does not touch the inbox', () async {
    when(drain.call)
        .thenAnswer((_) async => const Right(<ParsedNotification>[]));

    final Result<List<PendingCapture>> result = await build()();

    expect(result.getRight().toNullable(), isEmpty);
    verifyNever(() => ingest(any()));
  });

  test('a drain failure surfaces and nothing is ingested', () async {
    when(drain.call).thenAnswer(
      (_) async => const Left(UnexpectedFailure('channel down')),
    );

    final Result<List<PendingCapture>> result = await build()();

    expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    verifyNever(() => ingest(any()));
  });

  test('an ingest failure surfaces to the caller', () async {
    when(drain.call)
        .thenAnswer(
      (_) async => Right<Failure, List<ParsedNotification>>([nativeCapture()]),
    );
    when(() => ingest(any())).thenAnswer(
      (_) async => const Left<Failure, List<PendingCapture>>(
      DatabaseFailure('write failed'),
    ),
    );

    final Result<List<PendingCapture>> result = await build()();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
