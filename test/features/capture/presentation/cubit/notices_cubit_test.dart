import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/capture/domain/entities/duplicate_candidate.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_catalog_entry.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/discard_pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/find_duplicate_candidates.dart';
import 'package:billetudo/features/capture/domain/usecases/restore_pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_issuer_catalog.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_pending_captures.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_cubit.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../capture_mocks.dart';

class MockWatchPendingCaptures extends Mock implements WatchPendingCaptures {}

class MockWatchIssuerCatalog extends Mock implements WatchIssuerCatalog {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockFindDuplicateCandidates extends Mock
    implements FindDuplicateCandidates {}

class MockGetCategory extends Mock implements GetCategory {}

class MockDiscardPendingCapture extends Mock
    implements DiscardPendingCapture {}

class MockRestorePendingCapture extends Mock
    implements RestorePendingCapture {}

void main() {
  late MockWatchPendingCaptures watchCaptures;
  late MockWatchIssuerCatalog watchIssuers;
  late MockWatchAccounts watchAccounts;
  late MockFindDuplicateCandidates findDuplicates;
  late MockGetCategory getCategory;
  late MockDiscardPendingCapture discard;
  late MockRestorePendingCapture restore;

  setUpAll(() {
    registerCaptureFallbacks();
    registerFallbackValue(buildPendingCapture());
  });

  setUp(() {
    watchCaptures = MockWatchPendingCaptures();
    watchIssuers = MockWatchIssuerCatalog();
    watchAccounts = MockWatchAccounts();
    findDuplicates = MockFindDuplicateCandidates();
    getCategory = MockGetCategory();
    discard = MockDiscardPendingCapture();
    restore = MockRestorePendingCapture();

    when(() => watchIssuers()).thenAnswer(
      (_) => Stream.value(
        const Right<Failure, List<IssuerCatalogEntry>>([
          IssuerCatalogEntry(
            packageName: 'com.nu.production',
            displayName: 'Nu',
            kind: IssuerKind.bank,
            enabled: true,
          ),
        ]),
      ),
    );
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(
        Right<Failure, List<AccountWithBalance>>([
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', name: 'Cuenta Nu'),
            balanceMinor: 0,
          ),
        ]),
      ),
    );
    when(() => findDuplicates(any())).thenAnswer(
      (_) async => const Right<Failure, List<DuplicateCandidate>>([]),
    );
  });

  NoticesCubit build() => NoticesCubit(
        watchCaptures,
        watchIssuers,
        watchAccounts,
        findDuplicates,
        getCategory,
        discard,
        restore,
      );

  void stubCaptures(List<PendingCapture> captures) {
    when(() => watchCaptures()).thenAnswer(
      (_) => Stream.value(Right<Failure, List<PendingCapture>>(captures)),
    );
  }

  test('resolves the suggested account name and the issuer brand', () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    final cubit = build()..start();
    await pumpEventQueue();

    final item = cubit.state.captures.single;
    expect(item.accountName, 'Cuenta Nu');
    expect(item.issuerName, 'Nu');
    await cubit.close();
  });

  test('leaves the account name null when the capture suggests none',
      () async {
    stubCaptures([buildPendingCapture()]);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.captures.single.accountName, isNull);
    await cubit.close();
  });

  test('an empty inbox with issuers on is the neutral empty state', () async {
    stubCaptures(const []);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.isEmptyWithoutIssuers, isFalse);
    await cubit.close();
  });

  test('an empty inbox with every issuer off explains the cause', () async {
    when(() => watchIssuers()).thenAnswer(
      (_) => Stream.value(
        const Right<Failure, List<IssuerCatalogEntry>>([
          IssuerCatalogEntry(
            packageName: 'com.nu.production',
            displayName: 'Nu',
            kind: IssuerKind.bank,
          ),
        ]),
      ),
    );
    stubCaptures(const []);
    final cubit = build()..start();
    await pumpEventQueue();

    expect(cubit.state.isEmptyWithoutIssuers, isTrue);
    await cubit.close();
  });

  test('surfaces a possible duplicate against an existing transaction',
      () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    when(() => findDuplicates(any())).thenAnswer(
      (_) async => Right<Failure, List<DuplicateCandidate>>([
        TransactionDuplicateCandidate(
          Transaction(
            id: 'tx-1',
            accountId: 'acc-1',
            amountMinor: 4590000,
            currency: 'COP',
            type: TransactionType.expense,
            date: DateTime(2026, 9, 1, 11),
            source: TransactionSource.manual,
            note: 'Mercado de la semana',
            categoryId: 'cat-1',
            createdAt: DateTime(2026, 9, 1),
            updatedAt: 0,
          ),
          accountMatches: true,
        ),
      ]),
    );
    when(() => getCategory('cat-1')).thenAnswer(
      (_) async => Right<Failure, Category>(
        Category(
          id: 'cat-1',
          name: 'Mercado',
          kind: CategoryKind.expense,
          icon: 'shopping-cart',
          color: 'mint',
          sortOrder: 0,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
      ),
    );

    final cubit = build()..start();
    await pumpEventQueue();

    final duplicate = cubit.state.captures.single.duplicate;
    expect(duplicate, isNotNull);
    expect(duplicate!.transactionId, 'tx-1');
    expect(duplicate.title, 'Mercado de la semana');
    expect(duplicate.accountName, 'Cuenta Nu');
    expect(duplicate.categoryIcon, 'shopping-cart');
    await cubit.close();
  });

  test('discarding records the transaction the user pointed at and offers undo',
      () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    when(
      () => discard(any(), duplicateOfTransactionId: any(named: 'duplicateOfTransactionId')),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final cubit = build()..start();
    await pumpEventQueue();
    await cubit.discard('capture-1', duplicateOfTransactionId: 'tx-1');

    expect(cubit.state.discardedId, 'capture-1');
    verify(
      () => discard('capture-1', duplicateOfTransactionId: 'tx-1'),
    ).called(1);
    await cubit.close();
  });

  test('undo restores the capture and clears the affordance', () async {
    stubCaptures([buildPendingCapture(suggestedAccountId: 'acc-1')]);
    when(
      () => discard(any(), duplicateOfTransactionId: any(named: 'duplicateOfTransactionId')),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    when(() => restore(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final cubit = build()..start();
    await pumpEventQueue();
    await cubit.discard('capture-1');
    await cubit.undoDiscard();

    expect(cubit.state.discardedId, isNull);
    verify(() => restore('capture-1')).called(1);
    await cubit.close();
  });

  test('the overflow cap only applies while the notices section competes',
      () async {
    stubCaptures([
      buildPendingCapture(id: 'a'),
      buildPendingCapture(id: 'b'),
      buildPendingCapture(id: 'c'),
    ]);
    final cubit = build()..start();
    await pumpEventQueue();

    // `hasNotices` is still false on this branch, so nothing is collapsed.
    expect(cubit.state.visibleCaptures, hasLength(3));
    expect(cubit.state.hiddenCaptureCount, 0);
    await cubit.close();
  });
}
