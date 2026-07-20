// App startup smoke test: checks that BilletudoApp builds and renders the
// navigation shell (the Inicio tab of feature 04) without errors.

import 'package:billetudo/app.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchAccounts extends Mock implements WatchAccounts {}

class _MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class _MockWatchAuthSession extends Mock implements WatchAuthSession {}

class _MockWatchSyncStatus extends Mock implements WatchSyncStatus {}

class _MockRestoreTransaction extends Mock implements RestoreTransaction {}

void main() {
  setUpAll(() {
    // Stops google_fonts from trying to download fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    // The Home route resolves its cubit from `getIt`; wire it with use cases
    // whose streams never emit, so the app stays on the loading state (no DB).
    final watchAccounts = _MockWatchAccounts();
    final watchMonthTransactions = _MockWatchMonthTransactions();
    final watchAuthSession = _MockWatchAuthSession();
    final watchSyncStatus = _MockWatchSyncStatus();
    final restoreTransaction = _MockRestoreTransaction();
    when(watchAccounts.call).thenAnswer(
      (_) => const Stream<Result<List<AccountWithBalance>>>.empty(),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
    );
    when(watchAuthSession.call).thenAnswer(
      (_) => const Stream<AuthSession>.empty(),
    );
    when(watchSyncStatus.call).thenAnswer(
      (_) => const Stream<SyncState>.empty(),
    );
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        watchAccounts,
        watchMonthTransactions,
        watchAuthSession,
        watchSyncStatus,
        restoreTransaction,
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets('BilletudoApp arranca y muestra el shell de navegación',
      (tester) async {
    // The app now follows the device locale (no forced es_CO): pin the test
    // device to Spanish so the shell resolves to the es labels.
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    tester.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const BilletudoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    // The five-tab shell is up: the Inicio tab label is on screen.
    expect(find.text('Inicio'), findsOneWidget);
  });
}
