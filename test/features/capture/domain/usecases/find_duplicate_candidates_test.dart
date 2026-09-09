import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/duplicate_candidate.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_catalog_entry.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/find_duplicate_candidates.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

void main() {
  late MockPendingCaptureRepository repository;
  late MockIssuerSettingsRepository issuers;
  late FindDuplicateCandidates findCandidates;

  const wallet = 'com.google.android.apps.walletnfcrel';
  const bank = 'com.nu.production';
  const otherBank = 'com.bbva.nxt_col';

  final postedAt = DateTime(2026, 9, 1, 12);

  setUpAll(registerCaptureFallbacks);

  Transaction transaction({String accountId = 'account-1'}) => Transaction(
        id: 'tx-1',
        accountId: accountId,
        amountMinor: 4590000,
        currency: 'COP',
        type: TransactionType.expense,
        date: postedAt.subtract(const Duration(hours: 20)),
        source: TransactionSource.manual,
        createdAt: postedAt,
        updatedAt: postedAt.millisecondsSinceEpoch,
      );

  setUp(() {
    repository = MockPendingCaptureRepository();
    issuers = MockIssuerSettingsRepository();
    findCandidates = FindDuplicateCandidates(repository, issuers);

    when(
      () => repository.findMatchingTransactions(
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => const Right(<Transaction>[]));
    when(
      () => repository.findMatchingCaptures(
        excludeId: any(named: 'excludeId'),
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => const Right(<PendingCapture>[]));
    when(issuers.getIssuerCatalog).thenAnswer(
      (_) async => const Right([
        IssuerCatalogEntry(
          packageName: wallet,
          displayName: 'Google Wallet',
          kind: IssuerKind.wallet,
          enabled: true,
        ),
        IssuerCatalogEntry(
          packageName: bank,
          displayName: 'Nu',
          kind: IssuerKind.bank,
          enabled: true,
        ),
        IssuerCatalogEntry(
          packageName: otherBank,
          displayName: 'BBVA Colombia',
          kind: IssuerKind.bank,
          enabled: true,
        ),
      ]),
    );
  });

  List<DuplicateCandidate> noCandidates(Failure _) =>
      const <DuplicateCandidate>[];

  test('uses a wide window for transactions and a strict one to group',
      () async {
    await findCandidates(buildPendingCapture(sourcePackage: bank));

    verify(
      () => repository.findMatchingTransactions(
        amountMinor: 4590000,
        currency: 'COP',
        around: any(named: 'around'),
        window: FindDuplicateCandidates.transactionWindow,
      ),
    ).called(1);
    verify(
      () => repository.findMatchingCaptures(
        excludeId: 'capture-1',
        amountMinor: 4590000,
        currency: 'COP',
        around: any(named: 'around'),
        window: FindDuplicateCandidates.groupingWindow,
      ),
    ).called(1);
    expect(
      FindDuplicateCandidates.groupingWindow <
          FindDuplicateCandidates.transactionWindow,
      isTrue,
    );
  });

  test('marks a matching transaction as a possible duplicate only', () async {
    when(
      () => repository.findMatchingTransactions(
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => Right([transaction()]));

    final result = await findCandidates(
      buildPendingCapture(suggestedAccountId: 'account-1'),
    );

    final candidates = result.getOrElse(noCandidates);
    expect(candidates, hasLength(1));
    final candidate = candidates.single as TransactionDuplicateCandidate;
    expect(candidate.confidence, DuplicateConfidence.possible);
    expect(candidate.accountMatches, isTrue);
  });

  test('groups the wallet and the bank of one payment with high confidence',
      () async {
    when(
      () => repository.findMatchingCaptures(
        excludeId: any(named: 'excludeId'),
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer(
      (_) async => Right([
        buildPendingCapture(id: 'capture-2', sourcePackage: wallet),
      ]),
    );

    final result = await findCandidates(
      buildPendingCapture(sourcePackage: bank),
    );

    final candidate =
        result.getOrElse(noCandidates).single as CaptureDuplicateCandidate;
    expect(candidate.confidence, DuplicateConfidence.high);
    expect(candidate.sameIssuer, isFalse);
  });

  test('groups the same issuer notifying twice with high confidence', () async {
    when(
      () => repository.findMatchingCaptures(
        excludeId: any(named: 'excludeId'),
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer(
      (_) async => Right([
        buildPendingCapture(id: 'capture-2', sourcePackage: bank),
      ]),
    );

    final result = await findCandidates(
      buildPendingCapture(sourcePackage: bank),
    );

    final candidate =
        result.getOrElse(noCandidates).single as CaptureDuplicateCandidate;
    expect(candidate.confidence, DuplicateConfidence.high);
    expect(candidate.sameIssuer, isTrue);
  });

  test('two banks coinciding is a suggestion, not a grouping', () async {
    when(
      () => repository.findMatchingCaptures(
        excludeId: any(named: 'excludeId'),
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer(
      (_) async => Right([
        buildPendingCapture(id: 'capture-2', sourcePackage: otherBank),
      ]),
    );

    final result = await findCandidates(
      buildPendingCapture(sourcePackage: bank),
    );

    final candidate =
        result.getOrElse(noCandidates).single as CaptureDuplicateCandidate;
    expect(candidate.confidence, DuplicateConfidence.possible);
  });

  test('never merges nor discards on its own', () async {
    await findCandidates(buildPendingCapture());

    verifyNever(
      () => repository.discardCapture(
        any(),
        duplicateOfTransactionId: any(named: 'duplicateOfTransactionId'),
      ),
    );
    verifyNever(
      () => repository.confirmCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    );
  });

  test('propagates a lookup failure', () async {
    when(
      () => repository.findMatchingTransactions(
        amountMinor: any(named: 'amountMinor'),
        currency: any(named: 'currency'),
        around: any(named: 'around'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => const Left(DatabaseFailure('unavailable')));

    final result = await findCandidates(buildPendingCapture());

    expect(result.isLeft(), isTrue);
  });
}
