import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/capture_ingestion.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_catalog_entry.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/ingest_parsed_captures.dart';
import 'package:billetudo/features/capture/domain/usecases/suggest_account_for_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/suggest_category_for_merchant.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

void main() {
  late MockPendingCaptureRepository repository;
  late MockCaptureLearningRepository learning;
  late MockIssuerSettingsRepository issuers;
  late IngestParsedCaptures ingest;

  const enabledBank = 'com.nu.production';
  const disabledBank = 'com.bbva.nxt_col';

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    repository = MockPendingCaptureRepository();
    learning = MockCaptureLearningRepository();
    issuers = MockIssuerSettingsRepository();
    ingest = IngestParsedCaptures(
      repository,
      issuers,
      SuggestAccountForCapture(repository, issuers),
      SuggestCategoryForMerchant(learning),
    );

    when(issuers.getIssuerCatalog).thenAnswer(
      (_) async => const Right([
        IssuerCatalogEntry(
          packageName: enabledBank,
          displayName: 'Nu',
          kind: IssuerKind.bank,
          enabled: true,
        ),
        IssuerCatalogEntry(
          packageName: disabledBank,
          displayName: 'BBVA Colombia',
          kind: IssuerKind.bank,
        ),
      ]),
    );
    when(() => repository.findAccountIdByLast4(any()))
        .thenAnswer((_) async => const Right('account-1'));
    when(() => issuers.accountIdForPackage(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => learning.suggestedCategoryFor(any()))
        .thenAnswer((_) async => const Right('category-1'));
    when(() => repository.ingestParsedCaptures(any()))
        .thenAnswer((_) async => Right([buildPendingCapture()]));
  });

  ParsedCapture parsed({
    String sourcePackage = enabledBank,
    int amountMinor = 4590000,
    String? accountHint = '1234',
    String? merchantRaw = 'EXITO CALLE 80',
  }) =>
      ParsedCapture(
        sourcePackage: sourcePackage,
        postedAt: DateTime(2026, 9, 1, 12),
        amountMinor: amountMinor,
        currency: 'COP',
        entryType: TransactionType.expense,
        accountHint: accountHint,
        merchantRaw: merchantRaw,
      );

  List<CaptureIngestion> captured() =>
      verify(() => repository.ingestParsedCaptures(captureAny()))
          .captured
          .single as List<CaptureIngestion>;

  test('writes a pending capture and never a transaction', () async {
    final result = await ingest([parsed()]);

    expect(result.isRight(), isTrue);
    final ingestions = captured();
    expect(ingestions, hasLength(1));
    expect(ingestions.single.parsed.sourcePackage, enabledBank);
    expect(ingestions.single.suggestedAccountId, 'account-1');
    expect(ingestions.single.suggestedCategoryId, 'category-1');
  });

  test('drops captures from an issuer the user switched off', () async {
    final result = await ingest([parsed(sourcePackage: disabledBank)]);

    expect(result.getOrElse((_) => [buildPendingCapture()]), isEmpty);
    verifyNever(() => repository.ingestParsedCaptures(any()));
  });

  test('drops an invalid capture instead of storing it half-formed', () async {
    await ingest([parsed(), parsed(amountMinor: 0)]);

    expect(captured(), hasLength(1));
  });

  test('still ingests when a suggestion lookup fails', () async {
    when(() => repository.findAccountIdByLast4(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('accounts unavailable')),
    );

    await ingest([parsed()]);

    expect(captured().single.suggestedAccountId, isNull);
  });

  test('skips the last-4 lookup when the issuer sent no hint', () async {
    await ingest([parsed(accountHint: null)]);

    verifyNever(() => repository.findAccountIdByLast4(any()));
    expect(captured().single.suggestedAccountId, isNull);
  });

  // Nu and Nequi never quote the card digits, so the issuer link is the only
  // thing that can fill the account for them.
  test('falls back to the account linked to the issuer', () async {
    when(() => issuers.accountIdForPackage(enabledBank))
        .thenAnswer((_) async => const Right('nu-account'));

    await ingest([parsed(accountHint: null)]);

    expect(captured().single.suggestedAccountId, 'nu-account');
  });

  test('propagates a catalog failure instead of ingesting blindly', () async {
    when(issuers.getIssuerCatalog).thenAnswer(
      (_) async => const Left(UnexpectedFailure('prefs unavailable')),
    );

    final result = await ingest([parsed()]);

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.ingestParsedCaptures(any()));
  });

  test('does nothing on an empty buffer', () async {
    final result = await ingest(const <ParsedCapture>[]);

    expect(result.getOrElse((_) => [buildPendingCapture()]), isEmpty);
    verifyNever(issuers.getIssuerCatalog);
  });
}
