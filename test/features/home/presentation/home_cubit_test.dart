import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_global_monthly_budget_progress.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
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

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockWatchSyncStatus extends Mock implements WatchSyncStatus {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockWatchGlobalMonthlyBudgetProgress extends Mock
    implements WatchGlobalMonthlyBudgetProgress {}

void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchMonthTransactions watchMonthTransactions;
  late MockWatchAuthSession watchAuthSession;
  late MockWatchSyncStatus watchSyncStatus;
  late MockRestoreTransaction restoreTransaction;
  late MockWatchGlobalMonthlyBudgetProgress watchGlobalMonthlyBudgetProgress;

  final accounts = [buildActiveAccount()];
  final activity = [buildActivity(amountMinor: 82000)];
  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchMonthTransactions = MockWatchMonthTransactions();
    watchAuthSession = MockWatchAuthSession();
    watchSyncStatus = MockWatchSyncStatus();
    restoreTransaction = MockRestoreTransaction();
    watchGlobalMonthlyBudgetProgress = MockWatchGlobalMonthlyBudgetProgress();
    // Default: signed out; individual tests override to emit a session.
    when(() => watchAuthSession())
        .thenAnswer((_) => const Stream<AuthSession>.empty());
    // Default: the sync stream stays quiet, so the state keeps its initial
    // `syncStatus`; individual tests override to emit sync ticks.
    when(() => watchSyncStatus())
        .thenAnswer((_) => const Stream<SyncState>.empty());
    when(() => restoreTransaction(any()))
        .thenAnswer((_) async => const Right(unit));
    // Default: no qualifying budget; individual tests override.
    when(() => watchGlobalMonthlyBudgetProgress()).thenAnswer(
      (_) => Stream<Result<BudgetWithProgress?>>.value(const Right(null)),
    );
  });

  HomeCubit build() => HomeCubit(
        watchAccounts,
        watchMonthTransactions,
        watchAuthSession,
        watchSyncStatus,
        restoreTransaction,
        watchGlobalMonthlyBudgetProgress,
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
    'espera a ambos streams antes de salir de loading',
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
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.ready);
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cambiar a un mes pasado re-suscribe las transacciones (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(DateTime(2026));
    },
    verify: (cubit) {
      expect(cubit.state.month, DateTime(2026));
      verify(() => watchMonthTransactions(any())).called(2);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'seleccionar el mismo mes no re-suscribe las transacciones (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(cubit.state.currentMonth);
    },
    verify: (cubit) {
      // Same month is a no-op: only the initial subscription happened.
      verify(() => watchMonthTransactions(any())).called(1);
      expect(cubit.state.status, HomeStatus.ready);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'cambiar de mes pasa por loading antes de traer el nuevo mes (HU-04)',
    setUp: () {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream<Result<List<AccountWithBalance>>>.value(Right(accounts)),
      );
      // First subscription lands data; the second (past month) never emits, so
      // the cubit is caught mid-transition in loading.
      var call = 0;
      when(() => watchMonthTransactions(any())).thenAnswer((_) {
        call++;
        return call == 1
            ? Stream<Result<List<TransactionWithDetails>>>.value(
                Right(activity))
            : const Stream<Result<List<TransactionWithDetails>>>.empty();
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await cubit.selectMonth(DateTime(2026));
    },
    verify: (cubit) {
      expect(cubit.state.month, DateTime(2026));
      expect(cubit.state.status, HomeStatus.loading);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'el mes por defecto es el mes en curso (HU-04)',
    setUp: stubReady,
    build: build,
    verify: (cubit) {
      final now = DateTime.now();
      expect(cubit.state.month, DateTime(now.year, now.month));
      expect(cubit.state.currentMonth, cubit.state.month);
      expect(cubit.state.syncStatus, HomeSyncStatus.synced);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'no navega a un mes futuro (HU-04)',
    setUp: stubReady,
    build: build,
    act: (cubit) async {
      await cubit.start();
      final future = DateTime(cubit.state.currentMonth.year + 1);
      await cubit.selectMonth(future);
    },
    verify: (cubit) {
      expect(cubit.state.month, cubit.state.currentMonth);
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
        when(() => watchSyncStatus())
            .thenAnswer((_) => Stream<SyncState>.value(syncState));
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
        (_) => Stream<SyncState>.fromIterable(
          const [SyncState.offline, SyncState.syncing, SyncState.synced],
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
    final syncController = StreamController<SyncState>();
    when(() => watchSyncStatus()).thenAnswer((_) => syncController.stream);

    final cubit = build();
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, HomeStatus.failure);
    expect(cubit.state.failure, failure);

    syncController.add(SyncState.syncing);
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

  test('cerrar el cubit cancela las cinco suscripciones', () async {
    final accountsController =
        StreamController<Result<List<AccountWithBalance>>>.broadcast();
    final txController =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    final authController = StreamController<AuthSession>.broadcast();
    final syncController = StreamController<SyncState>.broadcast();
    final budgetProgressController =
        StreamController<Result<BudgetWithProgress?>>.broadcast();
    when(() => watchAccounts()).thenAnswer((_) => accountsController.stream);
    when(() => watchMonthTransactions(any()))
        .thenAnswer((_) => txController.stream);
    when(() => watchAuthSession()).thenAnswer((_) => authController.stream);
    when(() => watchSyncStatus()).thenAnswer((_) => syncController.stream);
    when(() => watchGlobalMonthlyBudgetProgress())
        .thenAnswer((_) => budgetProgressController.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(accountsController.hasListener, isFalse);
    expect(txController.hasListener, isFalse);
    expect(authController.hasListener, isFalse);
    expect(syncController.hasListener, isFalse);
    expect(budgetProgressController.hasListener, isFalse);
    await accountsController.close();
    await txController.close();
    await authController.close();
    await syncController.close();
    await budgetProgressController.close();
  });

  group('presupuesto global mensual en el hero (HU-03, aOhoY)', () {
    blocTest<HomeCubit, HomeState>(
      'expone budgetProgress cuando hay un presupuesto global mensual vigente',
      setUp: () {
        stubReady();
        when(() => watchGlobalMonthlyBudgetProgress()).thenAnswer(
          (_) => Stream<Result<BudgetWithProgress?>>.value(
            Right(buildHomeBudgetProgress()),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, HomeStatus.ready);
        expect(cubit.state.snapshot?.budgetProgress, isNotNull);
        expect(
            cubit.state.snapshot?.budgetProgress?.progress.amountMinor, 600000);
        expect(
            cubit.state.snapshot?.budgetProgress?.progress.spentMinor, 300000);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'deja budgetProgress en null cuando no hay presupuesto que califique',
      setUp: stubReady, // default stub in setUp() answers Right(null).
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, HomeStatus.ready);
        expect(cubit.state.snapshot?.budgetProgress, isNull);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'al navegar a un mes pasado, budgetProgress queda en null aunque haya '
      'un presupuesto vigente para el mes actual',
      setUp: () {
        stubReady();
        when(() => watchGlobalMonthlyBudgetProgress()).thenAnswer(
          (_) => Stream<Result<BudgetWithProgress?>>.value(
            Right(buildHomeBudgetProgress()),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        final past = DateTime(
          cubit.state.currentMonth.year,
          cubit.state.currentMonth.month - 1,
        );
        await cubit.selectMonth(past);
      },
      verify: (cubit) {
        expect(cubit.state.status, HomeStatus.ready);
        expect(cubit.state.snapshot?.budgetProgress, isNull);
      },
    );
  });
}
