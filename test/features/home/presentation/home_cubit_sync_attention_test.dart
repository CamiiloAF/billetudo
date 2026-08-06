import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_featured_budget_progress.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../home_fixtures.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockWatchSyncStatusDetails extends Mock
    implements WatchSyncStatusDetails {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockWatchFeaturedBudgetProgress extends Mock
    implements WatchFeaturedBudgetProgress {}

/// El cuarto estado del indicador del Home (HU-08). Cubre **dos** condiciones,
/// las dos ámbar: cambios retenidos en la cuarentena, y una última
/// sincronización exitosa de más de 24 h. La segunda es el incidente en
/// persona — "sincronizando" y "sincronizando desde hace tres días" no pueden
/// verse igual, y el indicador solo tiene cuatro estados para decirlo.
void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchMonthTransactions watchMonthTransactions;
  late MockWatchAuthSession watchAuthSession;
  late MockWatchSyncStatusDetails watchSyncStatus;
  late MockRestoreTransaction restoreTransaction;
  late MockWatchFeaturedBudgetProgress watchFeaturedBudgetProgress;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchMonthTransactions = MockWatchMonthTransactions();
    watchAuthSession = MockWatchAuthSession();
    watchSyncStatus = MockWatchSyncStatusDetails();
    restoreTransaction = MockRestoreTransaction();
    watchFeaturedBudgetProgress = MockWatchFeaturedBudgetProgress();
    when(() => watchAuthSession())
        .thenAnswer((_) => const Stream<AuthSession>.empty());
    when(() => restoreTransaction(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => watchFeaturedBudgetProgress()).thenAnswer(
      (_) => Stream<Result<BudgetWithProgress?>>.value(const Right(null)),
    );
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream<Result<List<AccountWithBalance>>>.value(
        Right([buildActiveAccount()]),
      ),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) => Stream<Result<List<TransactionWithDetails>>>.value(
        Right([buildActivity(amountMinor: 82000)]),
      ),
    );
  });

  /// Runs the cubit against a single snapshot and returns the resulting
  /// indicator state.
  Future<HomeSyncStatus> statusFor(SyncStatusSnapshot snapshot) async {
    when(() => watchSyncStatus())
        .thenAnswer((_) => Stream<SyncStatusSnapshot>.value(snapshot));
    final cubit = HomeCubit(
      watchAccounts,
      watchMonthTransactions,
      watchAuthSession,
      watchSyncStatus,
      restoreTransaction,
      watchFeaturedBudgetProgress,
    );
    addTearDown(cubit.close);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    return cubit.state.syncStatus;
  }

  SyncStatusSnapshot snapshot({
    required SyncState state,
    Duration? syncedAgo,
    int quarantined = 0,
  }) =>
      SyncStatusSnapshot(
        state: state,
        quarantinedCount: quarantined,
        lastSyncedAt:
            syncedAgo == null ? null : DateTime.now().subtract(syncedAgo),
        hasSyncedEver: syncedAgo != null,
      );

  group('condición 1: cambios retenidos en la cuarentena', () {
    test('stalled es atención aunque acabe de sincronizar', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.stalled,
            syncedAgo: const Duration(minutes: 1),
            quarantined: 2,
          ),
        ),
        HomeSyncStatus.attention,
      );
    });

    test('PRECEDENCIA: cambios sin subir mandan sobre la falta de conexión',
        () async {
      // El repositorio ya resuelve offline + cuarentena como `stalled`; lo que
      // este test fija es que el Home no lo degrade de vuelta a "sin conexión".
      expect(
        await statusFor(
          snapshot(
            state: SyncState.stalled,
            syncedAgo: const Duration(minutes: 1),
            quarantined: 5,
          ),
        ),
        HomeSyncStatus.attention,
      );
    });
  });

  group('condición 2: la última sincronización exitosa pasó de 24 h', () {
    test('exactamente 24 h YA es atención', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.synced,
            syncedAgo: const Duration(hours: 24),
          ),
        ),
        HomeSyncStatus.attention,
      );
    });

    test('23 h 59 min todavía NO es atención', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.synced,
            syncedAgo: const Duration(hours: 23, minutes: 59),
          ),
        ),
        HomeSyncStatus.synced,
      );
    });

    test('tres días sincronizando NO se ve como sincronizando', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.syncing,
            syncedAgo: const Duration(days: 3),
          ),
        ),
        HomeSyncStatus.attention,
      );
    });

    test('sin conexión desde hace tres días también es atención', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.offline,
            syncedAgo: const Duration(days: 3),
          ),
        ),
        HomeSyncStatus.attention,
      );
    });

    test('nunca sincronizó NO es atención: es informativo', () async {
      expect(
        await statusFor(snapshot(state: SyncState.offline)),
        HomeSyncStatus.offline,
      );
    });
  });

  group('los tres estados tranquilos siguen intactos', () {
    test('sincronizado y reciente: sincronizado', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.synced,
            syncedAgo: const Duration(minutes: 2),
          ),
        ),
        HomeSyncStatus.synced,
      );
    });

    test('sincronizando y reciente: sincronizando', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.syncing,
            syncedAgo: const Duration(minutes: 2),
          ),
        ),
        HomeSyncStatus.syncing,
      );
    });

    test('sin conexión y reciente: sin conexión, sin alarma', () async {
      expect(
        await statusFor(
          snapshot(
            state: SyncState.offline,
            syncedAgo: const Duration(minutes: 2),
          ),
        ),
        HomeSyncStatus.offline,
      );
    });
  });

  test(
      'el snapshot completo llega al estado: la hoja de la nube necesita '
      'la última sincronización, no solo el estado', () async {
    final value = snapshot(
      state: SyncState.stalled,
      syncedAgo: const Duration(days: 3),
      quarantined: 89,
    );
    when(() => watchSyncStatus())
        .thenAnswer((_) => Stream<SyncStatusSnapshot>.value(value));
    final cubit = HomeCubit(
      watchAccounts,
      watchMonthTransactions,
      watchAuthSession,
      watchSyncStatus,
      restoreTransaction,
      watchFeaturedBudgetProgress,
    );
    addTearDown(cubit.close);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.syncSnapshot.quarantinedCount, 89);
    expect(cubit.state.syncSnapshot.lastSyncedAt, value.lastSyncedAt);
  });
}
