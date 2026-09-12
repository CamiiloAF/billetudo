import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/ai/domain/entities/ai_access.dart';
import 'package:billetudo/features/ai/domain/usecases/check_ai_access.dart';
import 'package:billetudo/features/ai/domain/usecases/get_conversation_for_insight.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_featured_budget_progress.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_pending_capture_count.dart';
import 'package:billetudo/features/home/domain/entities/home_ai_insight.dart';
import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/domain/usecases/dismiss_home_insight.dart';
import 'package:billetudo/features/home/domain/usecases/record_home_insight_shown.dart';
import 'package:billetudo/features/home/domain/usecases/watch_has_any_budget.dart';
import 'package:billetudo/features/home/domain/usecases/watch_home_ai_insight.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/domain/usecases/watch_pending_scheduled_payment_count.dart';
import 'package:billetudo/features/home/domain/usecases/watch_recent_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../home_fixtures.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class MockWatchRecentTransactions extends Mock
    implements WatchRecentTransactions {}

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockWatchSyncStatus extends Mock implements WatchSyncStatusDetails {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockWatchFeaturedBudgetProgress extends Mock
    implements WatchFeaturedBudgetProgress {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class MockWatchHasAnyBudget extends Mock implements WatchHasAnyBudget {}

class MockWatchHomeAiInsight extends Mock implements WatchHomeAiInsight {}

class MockWatchPendingScheduledPaymentCount extends Mock
    implements WatchPendingScheduledPaymentCount {}

class MockWatchPendingCaptureCount extends Mock
    implements WatchPendingCaptureCount {}

class MockCheckAiAccess extends Mock implements CheckAiAccess {}

class MockGetConversationForInsight extends Mock
    implements GetConversationForInsight {}

class MockDismissHomeInsight extends Mock implements DismissHomeInsight {}

class MockRecordHomeInsightShown extends Mock
    implements RecordHomeInsightShown {}

void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchMonthTransactions watchMonthTransactions;
  late MockWatchRecentTransactions watchRecentTransactions;
  late MockWatchAuthSession watchAuthSession;
  late MockWatchSyncStatus watchSyncStatus;
  late MockRestoreTransaction restoreTransaction;
  late MockWatchFeaturedBudgetProgress watchFeaturedBudgetProgress;
  late MockGetBudgetById getBudgetById;
  late MockGetBudgetProgress getBudgetProgress;
  late MockWatchHasAnyBudget watchHasAnyBudget;
  late MockWatchHomeAiInsight watchHomeAiInsight;
  late MockWatchPendingScheduledPaymentCount watchPendingScheduledPaymentCount;
  late MockWatchPendingCaptureCount watchPendingCaptureCount;
  late MockCheckAiAccess checkAiAccess;
  late MockGetConversationForInsight getConversationForInsight;
  late MockDismissHomeInsight dismissHomeInsight;
  late MockRecordHomeInsightShown recordHomeInsightShown;

  final accounts = [buildActiveAccount()];
  final activity = [buildActivity(amountMinor: 82000)];
  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  /// A minimal `BudgetDetailData` for a global-monthly budget, matching
  /// `buildHomeBudgetProgress`'s profile — the reactive bundle
  /// `GetBudgetById` would stream once the featured budget is known.
  BudgetDetailData buildDetailData({String id = 'budget-1'}) =>
      BudgetDetailData(
        budget: buildHomeBudgetProgress(id: id).budget,
        scope: const BudgetScope.empty(),
        expenses: const [],
        categoryChildren: const {},
        scheduledTemplates: const [],
        pendingScheduledOccurrences: const [],
      );

  BudgetPeriodView buildView({
    required int index,
    required bool hasPrevious,
    required bool hasNext,
    int spentMinor = 300000,
    int amountMinor = 600000,
  }) =>
      BudgetPeriodView(
        window: BudgetPeriodWindow(
          start: DateTime(2026, 7 + index),
          endExclusive: DateTime(2026, 8 + index),
          index: index,
          status: BudgetWindowStatus.current,
          hasPrevious: hasPrevious,
          hasNext: hasNext,
        ),
        progress: BudgetProgress(
          amountMinor: amountMinor,
          spentMinor: spentMinor,
          daysLeft: 12,
        ),
        activity: const [],
      );

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      MonthSpending(
          month: DateTime(2026, 1),
          subtotals: const [],
          displayCurrency: 'COP'),
    );
    registerFallbackValue(buildDetailData());
    registerFallbackValue(HomeAiInsightType.spendingVsAverage);
  });

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchMonthTransactions = MockWatchMonthTransactions();
    watchRecentTransactions = MockWatchRecentTransactions();
    watchAuthSession = MockWatchAuthSession();
    watchSyncStatus = MockWatchSyncStatus();
    restoreTransaction = MockRestoreTransaction();
    watchFeaturedBudgetProgress = MockWatchFeaturedBudgetProgress();
    getBudgetById = MockGetBudgetById();
    getBudgetProgress = MockGetBudgetProgress();
    watchHasAnyBudget = MockWatchHasAnyBudget();
    watchHomeAiInsight = MockWatchHomeAiInsight();
    watchPendingScheduledPaymentCount = MockWatchPendingScheduledPaymentCount();
    watchPendingCaptureCount = MockWatchPendingCaptureCount();
    checkAiAccess = MockCheckAiAccess();
    getConversationForInsight = MockGetConversationForInsight();
    dismissHomeInsight = MockDismissHomeInsight();
    recordHomeInsightShown = MockRecordHomeInsightShown();
    when(() => getConversationForInsight(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => dismissHomeInsight(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => recordHomeInsightShown(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => watchHasAnyBudget())
        .thenAnswer((_) => Stream<Result<bool>>.value(const Right(true)));
    when(() => watchPendingScheduledPaymentCount())
        .thenAnswer((_) => Stream<Result<int>>.value(const Right(0)));
    when(() => watchPendingCaptureCount())
        .thenAnswer((_) => Stream<Result<int>>.value(const Right(0)));
    when(
      () => watchHomeAiInsight(
        month: any(named: 'month'),
        spending: any(named: 'spending'),
        hasAnyBudget: any(named: 'hasAnyBudget'),
        featuredBudget: any(named: 'featuredBudget'),
      ),
    ).thenAnswer(
        (_) => Stream<Result<HomeAiInsight?>>.value(const Right(null)));
    when(() => checkAiAccess())
        .thenAnswer((_) async => const Right(AiAccess.denied));
    // Default: signed out; individual tests override to emit a session.
    when(() => watchAuthSession())
        .thenAnswer((_) => const Stream<AuthSession>.empty());
    // Default: the sync stream stays quiet, so the state keeps its initial
    // `syncStatus`; individual tests override to emit sync ticks.
    when(() => watchSyncStatus())
        .thenAnswer((_) => const Stream<SyncStatusSnapshot>.empty());
    when(() => restoreTransaction(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => watchRecentTransactions()).thenAnswer(
      (_) =>
          Stream<Result<List<TransactionWithDetails>>>.value(Right(activity)),
    );
    // Default: no qualifying budget; individual tests override.
    when(() => watchFeaturedBudgetProgress()).thenAnswer(
      (_) => Stream<Result<BudgetWithProgress?>>.value(const Right(null)),
    );
  });

  HomeCubit build() => HomeCubit(
        watchAccounts,
        watchMonthTransactions,
        watchRecentTransactions,
        watchAuthSession,
        watchSyncStatus,
        restoreTransaction,
        watchFeaturedBudgetProgress,
        getBudgetById,
        getBudgetProgress,
        watchHasAnyBudget,
        watchHomeAiInsight,
        watchPendingScheduledPaymentCount,
        watchPendingCaptureCount,
        checkAiAccess,
        getConversationForInsight,
        dismissHomeInsight,
        recordHomeInsightShown,
      );

  void stubReady() {
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) =>
          Stream<Result<List<TransactionWithDetails>>>.value(Right(activity)),
    );
  }

  /// Wires the featured-budget chain (`WatchFeaturedBudgetProgress` →
  /// `GetBudgetById` → `GetBudgetProgress`) for [id], serving [current] as
  /// the "index null" view and [byIndex] for any explicit index navigated to
  /// (HU-05's stepper).
  void stubFeaturedBudget({
    String id = 'budget-1',
    required BudgetPeriodView current,
    Map<int, BudgetPeriodView> byIndex = const {},
  }) {
    final data = buildDetailData(id: id);
    when(() => watchFeaturedBudgetProgress()).thenAnswer(
      (_) => Stream<Result<BudgetWithProgress?>>.value(
        Right(
          BudgetWithProgress(
            budget: data.budget,
            scope: data.scope,
            window: current.window,
            progress: current.progress,
          ),
        ),
      ),
    );
    when(() => getBudgetById(id)).thenAnswer(
      (_) => Stream<Result<BudgetDetailData>>.value(Right(data)),
    );
    when(() => getBudgetProgress(any(), now: any(named: 'now'), index: null))
        .thenReturn(current);
    for (final entry in byIndex.entries) {
      when(
        () => getBudgetProgress(
          any(),
          now: any(named: 'now'),
          index: entry.key,
        ),
      ).thenReturn(entry.value);
    }
  }

  blocTest<HomeCubit, HomeState>(
    'combina cuentas + transacciones y emite ready con el gasto del mes',
    setUp: stubReady,
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.ready);
      expect(cubit.state.spending?.displayTotalMinor, 82000);
      expect(cubit.state.recentActivity, hasLength(1));
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'espera a todos los streams antes de salir de loading',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      // Transactions never emit: the cubit must stay loading.
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.status, HomeStatus.loading),
  );

  blocTest<HomeCubit, HomeState>(
    'un fallo de cualquier stream deja el estado en failure (HU-10)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Left(DatabaseFailure('boom')),
        ),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.status, HomeStatus.failure),
  );

  blocTest<HomeCubit, HomeState>(
    'sin movimientos: ready y vacío (HU-08)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Right(<TransactionWithDetails>[]),
        ),
      );
      when(() => watchRecentTransactions()).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Right(<TransactionWithDetails>[]),
        ),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.ready);
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  // Criterion 1: "Movimientos recientes" is decoupled from any month —
  // covered end to end (real repositories) by
  // `watch_month_transactions_vs_movimientos_test.dart`. Here the cubit-level
  // guarantee is that the recent feed comes from `WatchRecentTransactions`,
  // not `WatchMonthTransactions` (never re-subscribed, never touched by
  // period navigation below).
  blocTest<HomeCubit, HomeState>(
    'el feed reciente viene de WatchRecentTransactions, no de las '
    'transacciones del mes',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      when(() => watchMonthTransactions(any())).thenAnswer(
        (_) => Stream<Result<List<TransactionWithDetails>>>.value(
          const Right(<TransactionWithDetails>[]),
        ),
      );
      when(() => watchRecentTransactions()).thenAnswer(
        (_) =>
            Stream<Result<List<TransactionWithDetails>>>.value(Right(activity)),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.recentActivity, hasLength(1));
      // The month-scoped stream is only ever queried once, for `now` — never
      // re-subscribed, since there is no navigable "visible month" anymore.
      verify(() => watchMonthTransactions(any())).called(1);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'la sesión con nombre puebla user sin gatear el status (HU-07)',
    setUp: () {
      stubReady();
      when(() => watchAuthSession()).thenAnswer(
        (_) => Stream<AuthSession>.value(const AuthSession.signedIn(user)),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.user, user);
      // The status still depends only on accounts + transactions.
      expect(cubit.state.status, HomeStatus.ready);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cerrar sesión limpia user a null (HU-07)',
    setUp: () {
      stubReady();
      when(() => watchAuthSession()).thenAnswer(
        (_) => Stream<AuthSession>.fromIterable(const [
          AuthSession.signedIn(user),
          AuthSession.signedOut(),
        ]),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.user, isNull),
  );

  blocTest<HomeCubit, HomeState>(
    'sin sesión: user queda null (local-first, HU-07)',
    setUp: stubReady,
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.user, isNull),
  );

  for (final (syncState, expected) in const [
    (SyncState.synced, HomeSyncStatus.synced),
    (SyncState.syncing, HomeSyncStatus.syncing),
    (SyncState.offline, HomeSyncStatus.offline),
  ]) {
    blocTest<HomeCubit, HomeState>(
      'el estado de sync $syncState se refleja en syncStatus (HU-10)',
      setUp: () {
        stubReady();
        when(() => watchSyncStatus()).thenAnswer(
          (_) => Stream<SyncStatusSnapshot>.value(
            SyncStatusSnapshot(state: syncState, quarantinedCount: 0),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.syncStatus, expected);
        // The indicator is passive: it never turns the Home into an error.
        expect(cubit.state.status, HomeStatus.ready);
      },
    );
  }

  blocTest<HomeCubit, HomeState>(
    'el sync sigue los cambios sucesivos del stream (HU-10)',
    setUp: () {
      stubReady();
      when(() => watchSyncStatus()).thenAnswer(
        (_) => Stream<SyncStatusSnapshot>.fromIterable(
          const [
            SyncStatusSnapshot(
              state: SyncState.offline,
              quarantinedCount: 0,
            ),
            SyncStatusSnapshot(
              state: SyncState.syncing,
              quarantinedCount: 0,
            ),
            SyncStatusSnapshot(state: SyncState.synced, quarantinedCount: 0),
          ],
        ),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.syncStatus, HomeSyncStatus.synced),
  );

  test('un tick de sync no borra el failure que el body sigue mostrando',
      () async {
    const failure = DatabaseFailure('boom');
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream<Result<List<AccountWithBalance>>>.value(
        const Left(failure),
      ),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) =>
          Stream<Result<List<TransactionWithDetails>>>.value(Right(activity)),
    );
    final syncController = StreamController<SyncStatusSnapshot>();
    when(() => watchSyncStatus()).thenAnswer((_) => syncController.stream);

    final cubit = build();
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, HomeStatus.failure);
    expect(cubit.state.failure, failure);

    syncController.add(
      const SyncStatusSnapshot(state: SyncState.syncing, quarantinedCount: 0),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.syncStatus, HomeSyncStatus.syncing);
    // Regression: `copyWith` drops `failure` when omitted, so `_onSyncState`
    // must re-pass it — otherwise the error banner would vanish on a tick.
    expect(cubit.state.failure, failure);
    expect(cubit.state.status, HomeStatus.failure);

    await cubit.close();
    await syncController.close();
  });

  group('borrar y deshacer desde el detalle (HU-05)', () {
    blocTest<HomeCubit, HomeState>(
      'notifyExternalDelete ofrece deshacer con el id de la transacción',
      setUp: stubReady,
      build: build,
      act: (cubit) => cubit.notifyExternalDelete('tx-1'),
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, 'tx-1');
        verifyNever(() => restoreTransaction(any()));
      },
    );

    blocTest<HomeCubit, HomeState>(
      'undoDelete restaura la transacción y limpia el pendiente',
      setUp: stubReady,
      build: build,
      act: (cubit) async {
        cubit.notifyExternalDelete('tx-1');
        await cubit.undoDelete();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verify(() => restoreTransaction('tx-1')).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'dismissUndo limpia el pendiente sin restaurar',
      setUp: stubReady,
      build: build,
      act: (cubit) {
        cubit.notifyExternalDelete('tx-1');
        cubit.dismissUndo();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verifyNever(() => restoreTransaction(any()));
      },
    );

    blocTest<HomeCubit, HomeState>(
      'undoDelete sin pendiente no llama al caso de uso',
      setUp: stubReady,
      build: build,
      act: (cubit) => cubit.undoDelete(),
      verify: (_) => verifyNever(() => restoreTransaction(any())),
    );
  });

  group('selectMonth navega el mes visible del fallback (HU-04)', () {
    blocTest<HomeCubit, HomeState>(
      're-suscribe watchMonthTransactions al nuevo mes y actualiza el '
      'snapshot',
      setUp: () {
        when(() => watchAccounts()).thenAnswer(
          (_) => Stream<Result<List<AccountWithBalance>>>.value(
            Right(accounts),
          ),
        );
        // `start()` always seeds `_visibleMonth` from the real `DateTime.now()`
        // — stub it broadly, then override the specific target month picked
        // below (mocktail matches the most specific/last-registered stub).
        when(() => watchMonthTransactions(any())).thenAnswer(
          (_) => Stream<Result<List<TransactionWithDetails>>>.value(
            Right(activity),
          ),
        );
        final junActivity = [buildActivity(id: 'tx-jun', amountMinor: 55000)];
        when(() => watchMonthTransactions(DateTime(2026, 6))).thenAnswer(
          (_) => Stream<Result<List<TransactionWithDetails>>>.value(
            Right(junActivity),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.selectMonth(DateTime(2026, 6, 15));
      },
      verify: (cubit) {
        expect(cubit.state.spending?.month, DateTime(2026, 6));
        expect(cubit.state.spending?.displayTotalMinor, 55000);
        verify(() => watchMonthTransactions(DateTime(2026, 6))).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'normaliza cualquier día del mes al primero antes de comparar: un día '
      'distinto dentro del mismo mes ya visible no re-suscribe',
      setUp: stubReady,
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        final now = DateTime.now();
        // Same year/month `start()` already subscribed to, different day —
        // must normalize to the same key and no-op.
        cubit.selectMonth(DateTime(now.year, now.month, 28));
      },
      verify: (cubit) {
        verify(() => watchMonthTransactions(any())).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'seleccionar el mismo mes ya visible es un no-op: no re-suscribe',
      setUp: () {
        when(() => watchAccounts()).thenAnswer(
          (_) => Stream<Result<List<AccountWithBalance>>>.value(
            Right(accounts),
          ),
        );
        final now = DateTime.now();
        when(() => watchMonthTransactions(DateTime(now.year, now.month)))
            .thenAnswer(
          (_) => Stream<Result<List<TransactionWithDetails>>>.value(
            Right(activity),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        final now = DateTime.now();
        cubit.selectMonth(DateTime(now.year, now.month, 5));
      },
      verify: (_) => verify(() => watchMonthTransactions(any())).called(1),
    );

    blocTest<HomeCubit, HomeState>(
      'un mes elegido no toca la lista de recientes (criterio 1)',
      setUp: () {
        when(() => watchAccounts()).thenAnswer(
          (_) => Stream<Result<List<AccountWithBalance>>>.value(
            Right(accounts),
          ),
        );
        when(() => watchMonthTransactions(any())).thenAnswer(
          (_) => Stream<Result<List<TransactionWithDetails>>>.value(
            Right(activity),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.selectMonth(DateTime(2026, 3));
      },
      verify: (_) => verify(() => watchRecentTransactions()).called(1),
    );
  });

  test('cerrar el cubit cancela las siete suscripciones', () async {
    final accountsController =
        StreamController<Result<List<AccountWithBalance>>>.broadcast();
    final monthTxController =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    final recentTxController =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    final authController = StreamController<AuthSession>.broadcast();
    final syncController = StreamController<SyncStatusSnapshot>.broadcast();
    final budgetProgressController =
        StreamController<Result<BudgetWithProgress?>>.broadcast();
    final budgetDataController =
        StreamController<Result<BudgetDetailData>>.broadcast();
    when(() => watchAccounts()).thenAnswer((_) => accountsController.stream);
    when(() => watchMonthTransactions(any()))
        .thenAnswer((_) => monthTxController.stream);
    when(() => watchRecentTransactions())
        .thenAnswer((_) => recentTxController.stream);
    when(() => watchAuthSession()).thenAnswer((_) => authController.stream);
    when(() => watchSyncStatus()).thenAnswer((_) => syncController.stream);
    when(() => watchFeaturedBudgetProgress())
        .thenAnswer((_) => budgetProgressController.stream);

    final cubit = build();
    await cubit.start();
    // Feature the budget mid-flight so the second-level subscription
    // (`getBudgetById`) is live too, then close and check it unwinds as well.
    final data = buildDetailData();
    when(() => getBudgetById('budget-1'))
        .thenAnswer((_) => budgetDataController.stream);
    budgetProgressController.add(
      Right(
        BudgetWithProgress(
          budget: data.budget,
          scope: data.scope,
          window: buildView(index: 0, hasPrevious: false, hasNext: true).window,
          progress:
              buildView(index: 0, hasPrevious: false, hasNext: true).progress,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.close();

    expect(accountsController.hasListener, isFalse);
    expect(monthTxController.hasListener, isFalse);
    expect(recentTxController.hasListener, isFalse);
    expect(authController.hasListener, isFalse);
    expect(syncController.hasListener, isFalse);
    expect(budgetProgressController.hasListener, isFalse);
    expect(budgetDataController.hasListener, isFalse);
    await accountsController.close();
    await monthTxController.close();
    await recentTxController.close();
    await authController.close();
    await syncController.close();
    await budgetProgressController.close();
    await budgetDataController.close();
  });

  group('presupuesto destacado en el hero (HU-03/HU-05, aOhoY)', () {
    blocTest<HomeCubit, HomeState>(
      'expone budgetProgress cuando hay un presupuesto destacado vigente',
      setUp: () {
        stubReady();
        stubFeaturedBudget(
          current: buildView(index: 0, hasPrevious: false, hasNext: true),
        );
      },
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, HomeStatus.ready);
        expect(cubit.state.budgetProgress, isNotNull);
        expect(cubit.state.budgetProgress?.progress.amountMinor, 600000);
        expect(cubit.state.budgetProgress?.progress.spentMinor, 300000);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'deja budgetProgress en null cuando no hay presupuesto que califique',
      setUp: stubReady, // default stub in setUp() answers Right(null).
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, HomeStatus.ready);
        expect(cubit.state.budgetProgress, isNull);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'criterio 4: nextPeriod navega a la ventana siguiente '
      '(GetBudgetProgress con index+1)',
      setUp: () {
        stubReady();
        stubFeaturedBudget(
          current: buildView(index: 0, hasPrevious: false, hasNext: true),
          byIndex: {
            1: buildView(
              index: 1,
              hasPrevious: true,
              hasNext: false,
              spentMinor: 450000,
            ),
          },
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        // `WatchFeaturedBudgetProgress` → `GetBudgetById` is a two-hop
        // reactive chain (see `HomeCubit`'s class docs): `start()` only
        // awaits the subscriptions themselves, not their first emissions —
        // flush the queued microtasks so the featured budget is actually
        // known before stepping its period.
        await Future<void>.delayed(Duration.zero);
        cubit.nextPeriod();
      },
      verify: (cubit) {
        expect(cubit.state.budgetProgress?.window.index, 1);
        expect(cubit.state.budgetProgress?.progress.spentMinor, 450000);
        expect(cubit.state.budgetProgress?.window.hasNext, isFalse);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'criterio 4: previousPeriod es un no-op en el borde (hasPrevious '
      'false)',
      setUp: () {
        stubReady();
        stubFeaturedBudget(
          current: buildView(index: 0, hasPrevious: false, hasNext: true),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit.previousPeriod();
      },
      verify: (cubit) {
        expect(cubit.state.budgetProgress?.window.index, 0);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'sin presupuesto destacado: nextPeriod/previousPeriod son no-op',
      setUp: stubReady,
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit.nextPeriod();
        cubit.previousPeriod();
      },
      verify: (cubit) => expect(cubit.state.budgetProgress, isNull),
    );

    blocTest<HomeCubit, HomeState>(
      'la lista de recientes no se re-suscribe al navegar el período '
      '(criterio 1)',
      setUp: () {
        stubReady();
        stubFeaturedBudget(
          current: buildView(index: 0, hasPrevious: false, hasNext: true),
          byIndex: {
            1: buildView(index: 1, hasPrevious: true, hasNext: false),
          },
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.nextPeriod();
      },
      verify: (_) => verify(() => watchRecentTransactions()).called(1),
    );
  });

  group(
    'resolución del vínculo insight↔conversación (bugfix item 7)',
    () {
      const spendingInsight = HomeAiInsight(
        type: HomeAiInsightType.spendingVsAverage,
        percentDelta: 15,
        currency: 'COP',
      );

      blocTest<HomeCubit, HomeState>(
        'GetConversationForInsight con id: aiInsight.conversationId queda '
        'poblado',
        setUp: () {
          stubReady();
          when(
            () => watchHomeAiInsight(
              month: any(named: 'month'),
              spending: any(named: 'spending'),
              hasAnyBudget: any(named: 'hasAnyBudget'),
              featuredBudget: any(named: 'featuredBudget'),
            ),
          ).thenAnswer(
            (_) => Stream<Result<HomeAiInsight?>>.value(
              const Right(spendingInsight),
            ),
          );
          when(() => getConversationForInsight('spendingVsAverage'))
              .thenAnswer((_) async => const Right('conv-42'));
        },
        build: build,
        act: (cubit) async {
          await cubit.start();
          await Future<void>.delayed(Duration.zero);
        },
        verify: (cubit) {
          expect(cubit.state.aiInsight?.conversationId, 'conv-42');
        },
      );

      blocTest<HomeCubit, HomeState>(
        'GetConversationForInsight sin id: aiInsight.conversationId queda '
        'null (el chip debe mostrar "iniciar")',
        setUp: () {
          stubReady();
          when(
            () => watchHomeAiInsight(
              month: any(named: 'month'),
              spending: any(named: 'spending'),
              hasAnyBudget: any(named: 'hasAnyBudget'),
              featuredBudget: any(named: 'featuredBudget'),
            ),
          ).thenAnswer(
            (_) => Stream<Result<HomeAiInsight?>>.value(
              const Right(spendingInsight),
            ),
          );
          when(() => getConversationForInsight('spendingVsAverage'))
              .thenAnswer((_) async => const Right(null));
        },
        build: build,
        act: (cubit) async {
          await cubit.start();
          await Future<void>.delayed(Duration.zero);
        },
        verify: (cubit) {
          expect(cubit.state.aiInsight?.conversationId, isNull);
        },
      );

      test(
        'una resolución vieja no pisa un resultado más reciente (ticket '
        'guard contra carreras)',
        () async {
          stubReady();
          final insightController = StreamController<Result<HomeAiInsight?>>();
          when(
            () => watchHomeAiInsight(
              month: any(named: 'month'),
              spending: any(named: 'spending'),
              hasAnyBudget: any(named: 'hasAnyBudget'),
              featuredBudget: any(named: 'featuredBudget'),
            ),
          ).thenAnswer((_) => insightController.stream);

          // Two same-type insights (so both hit `GetConversationForInsight`
          // with the same key) but distinguishable by `percentDelta` — the
          // first lookup is slow, the second is fast, and the guard must
          // keep whichever insight is *currently shown* from being
          // overwritten by the stale reply that lands after it.
          const insightA = HomeAiInsight(
            type: HomeAiInsightType.spendingVsAverage,
            percentDelta: 10,
            currency: 'COP',
          );
          const insightB = HomeAiInsight(
            type: HomeAiInsightType.spendingVsAverage,
            percentDelta: 20,
            currency: 'COP',
          );

          final slowLookup = Completer<Result<String?>>();
          final fastLookup = Completer<Result<String?>>();
          var callCount = 0;
          when(() => getConversationForInsight('spendingVsAverage'))
              .thenAnswer((_) {
            callCount++;
            return callCount == 1 ? slowLookup.future : fastLookup.future;
          });

          final cubit = build();
          await cubit.start();
          await Future<void>.delayed(Duration.zero);

          insightController.add(const Right(insightA));
          await Future<void>.delayed(Duration.zero);
          insightController.add(const Right(insightB));
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.aiInsight, insightB);

          // The fast (second) lookup resolves first.
          fastLookup.complete(const Right('conv-fresh'));
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.aiInsight?.conversationId, 'conv-fresh');

          // The stale (first) lookup resolves late — must not overwrite it.
          slowLookup.complete(const Right('conv-stale'));
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.aiInsight?.conversationId, 'conv-fresh');

          await cubit.close();
          await insightController.close();
        },
      );

      blocTest<HomeCubit, HomeState>(
        'refreshAiInsightConversation vuelve a consultar y actualiza el '
        'estado',
        setUp: () {
          stubReady();
          when(
            () => watchHomeAiInsight(
              month: any(named: 'month'),
              spending: any(named: 'spending'),
              hasAnyBudget: any(named: 'hasAnyBudget'),
              featuredBudget: any(named: 'featuredBudget'),
            ),
          ).thenAnswer(
            (_) => Stream<Result<HomeAiInsight?>>.value(
              const Right(spendingInsight),
            ),
          );
          when(() => getConversationForInsight('spendingVsAverage'))
              .thenAnswer((_) async => const Right(null));
        },
        build: build,
        act: (cubit) async {
          await cubit.start();
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.aiInsight?.conversationId, isNull);
          // Router calls this right after the assistant screen is popped
          // back to Home, once a conversation now exists for the insight.
          when(() => getConversationForInsight('spendingVsAverage'))
              .thenAnswer((_) async => const Right('conv-99'));
          cubit.refreshAiInsightConversation();
          await Future<void>.delayed(Duration.zero);
        },
        verify: (cubit) {
          expect(cubit.state.aiInsight?.conversationId, 'conv-99');
          verify(() => getConversationForInsight('spendingVsAverage'))
              .called(2);
        },
      );
    },
  );

  group('persistencia de insights (bugfix: no debe reaparecer siempre)', () {
    const spendingInsight = HomeAiInsight(
      type: HomeAiInsightType.spendingVsAverage,
      percentDelta: 15,
      currency: 'COP',
    );

    blocTest<HomeCubit, HomeState>(
      'dismissAiInsight limpia el estado local y persiste el descarte vía '
      'DismissHomeInsight',
      setUp: () {
        stubReady();
        when(
          () => watchHomeAiInsight(
            month: any(named: 'month'),
            spending: any(named: 'spending'),
            hasAnyBudget: any(named: 'hasAnyBudget'),
            featuredBudget: any(named: 'featuredBudget'),
          ),
        ).thenAnswer(
          (_) => Stream<Result<HomeAiInsight?>>.value(
            const Right(spendingInsight),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.dismissAiInsight();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.aiInsight, isNull);
        verify(() => dismissHomeInsight(HomeAiInsightType.spendingVsAverage))
            .called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'dismissAiInsight con createBudget no persiste nada: es un estado '
      'forzado sin "Ahora no"',
      setUp: () {
        stubReady();
        when(
          () => watchHomeAiInsight(
            month: any(named: 'month'),
            spending: any(named: 'spending'),
            hasAnyBudget: any(named: 'hasAnyBudget'),
            featuredBudget: any(named: 'featuredBudget'),
          ),
        ).thenAnswer(
          (_) => Stream<Result<HomeAiInsight?>>.value(
            const Right(HomeAiInsight.createBudget()),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.dismissAiInsight();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(() => dismissHomeInsight(any()));
      },
    );

    test(
      'RecordHomeInsightShown se llama solo en la transición hacia un tipo '
      'nuevo, no en cada recompute que mantiene el mismo tipo',
      () async {
        stubReady();
        final insightController = StreamController<Result<HomeAiInsight?>>();
        when(
          () => watchHomeAiInsight(
            month: any(named: 'month'),
            spending: any(named: 'spending'),
            hasAnyBudget: any(named: 'hasAnyBudget'),
            featuredBudget: any(named: 'featuredBudget'),
          ),
        ).thenAnswer((_) => insightController.stream);

        final cubit = build();
        await cubit.start();
        await Future<void>.delayed(Duration.zero);

        insightController.add(const Right(spendingInsight));
        await Future<void>.delayed(Duration.zero);
        // Same type re-emitted (e.g. a benign recompute) must not re-fire.
        insightController.add(
          const Right(
            HomeAiInsight(
              type: HomeAiInsightType.spendingVsAverage,
              percentDelta: 20,
              currency: 'COP',
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => recordHomeInsightShown(HomeAiInsightType.spendingVsAverage),
        ).called(1);

        // A different type transitions in -> fires again.
        insightController.add(
          const Right(
            HomeAiInsight(
              type: HomeAiInsightType.budgetProjectionRisk,
              overageMinor: 1000,
              currency: 'COP',
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => recordHomeInsightShown(HomeAiInsightType.budgetProjectionRisk),
        ).called(1);
        verifyNever(
            () => recordHomeInsightShown(HomeAiInsightType.createBudget));

        await cubit.close();
        await insightController.close();
      },
    );

    blocTest<HomeCubit, HomeState>(
      'RecordHomeInsightShown nunca se llama para createBudget',
      setUp: () {
        stubReady();
        when(
          () => watchHomeAiInsight(
            month: any(named: 'month'),
            spending: any(named: 'spending'),
            hasAnyBudget: any(named: 'hasAnyBudget'),
            featuredBudget: any(named: 'featuredBudget'),
          ),
        ).thenAnswer(
          (_) => Stream<Result<HomeAiInsight?>>.value(
            const Right(HomeAiInsight.createBudget()),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(() => recordHomeInsightShown(any()));
      },
    );
  });
}
