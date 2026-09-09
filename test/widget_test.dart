// App startup smoke test: checks that BilletudoApp builds and renders the
// navigation shell (the Inicio tab of feature 04) without errors.

import 'package:billetudo/app.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/ai/domain/entities/ai_access.dart';
import 'package:billetudo/features/ai/domain/usecases/check_ai_access.dart';
import 'package:billetudo/features/ai/domain/usecases/get_conversation_for_insight.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_featured_budget_progress.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_pending_capture_count.dart';
import 'package:billetudo/features/home/domain/usecases/dismiss_home_insight.dart';
import 'package:billetudo/features/home/domain/usecases/record_home_insight_shown.dart';
import 'package:billetudo/features/home/domain/usecases/watch_has_any_budget.dart';
import 'package:billetudo/features/home/domain/usecases/watch_home_ai_insight.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/domain/usecases/watch_pending_scheduled_payment_count.dart';
import 'package:billetudo/features/home/domain/usecases/watch_recent_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchAccounts extends Mock implements WatchAccounts {}

class _MockThemeModeCubit extends MockCubit<ThemeMode>
    implements ThemeModeCubit {}

class _MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class _MockWatchRecentTransactions extends Mock
    implements WatchRecentTransactions {}

class _MockWatchAuthSession extends Mock implements WatchAuthSession {}

class _MockWatchSyncStatus extends Mock implements WatchSyncStatusDetails {}

class _MockRestoreTransaction extends Mock implements RestoreTransaction {}

class _MockWatchFeaturedBudgetProgress extends Mock
    implements WatchFeaturedBudgetProgress {}

class _MockGetBudgetById extends Mock implements GetBudgetById {}

class _MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class _MockWatchHasAnyBudget extends Mock implements WatchHasAnyBudget {}

class _MockWatchHomeAiInsight extends Mock implements WatchHomeAiInsight {}

class _MockWatchPendingScheduledPaymentCount extends Mock
    implements WatchPendingScheduledPaymentCount {}

class _MockWatchPendingCaptureCount extends Mock
    implements WatchPendingCaptureCount {}

class _MockCheckAiAccess extends Mock implements CheckAiAccess {}

class _MockGetConversationForInsight extends Mock
    implements GetConversationForInsight {}

class _MockDismissHomeInsight extends Mock implements DismissHomeInsight {}

class _MockRecordHomeInsightShown extends Mock
    implements RecordHomeInsightShown {}

class _MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

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
    final watchRecentTransactions = _MockWatchRecentTransactions();
    final watchAuthSession = _MockWatchAuthSession();
    final watchSyncStatus = _MockWatchSyncStatus();
    final restoreTransaction = _MockRestoreTransaction();
    final watchFeaturedBudgetProgress = _MockWatchFeaturedBudgetProgress();
    final getBudgetById = _MockGetBudgetById();
    final getBudgetProgress = _MockGetBudgetProgress();
    final watchHasAnyBudget = _MockWatchHasAnyBudget();
    final watchHomeAiInsight = _MockWatchHomeAiInsight();
    final watchPendingScheduledPaymentCount =
        _MockWatchPendingScheduledPaymentCount();
    final watchPendingCaptureCount = _MockWatchPendingCaptureCount();
    final checkAiAccess = _MockCheckAiAccess();
    final getConversationForInsight = _MockGetConversationForInsight();
    final dismissHomeInsight = _MockDismissHomeInsight();
    final recordHomeInsightShown = _MockRecordHomeInsightShown();
    when(watchAccounts.call).thenAnswer(
      (_) => const Stream<Result<List<AccountWithBalance>>>.empty(),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
    );
    when(watchRecentTransactions.call).thenAnswer(
      (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
    );
    when(watchAuthSession.call).thenAnswer(
      (_) => const Stream<AuthSession>.empty(),
    );
    when(watchSyncStatus.call).thenAnswer(
      (_) => const Stream<SyncStatusSnapshot>.empty(),
    );
    when(watchFeaturedBudgetProgress.call).thenAnswer(
      (_) => const Stream<Result<BudgetWithProgress?>>.empty(),
    );
    when(watchHasAnyBudget.call)
        .thenAnswer((_) => const Stream<Result<bool>>.empty());
    when(watchPendingScheduledPaymentCount.call)
        .thenAnswer((_) => const Stream<Result<int>>.empty());
    when(watchPendingCaptureCount.call)
        .thenAnswer((_) => const Stream<Result<int>>.empty());
    // `HomeCubit.start()` asks the server whether the assistant is available.
    // This smoke test is not about IA: `denied` is the neutral answer (it is
    // also the fail-closed default of `AiAccess`), so the AI card stays hidden
    // and nothing else on the shell changes — without it the un-stubbed mock
    // returns `null` and the cubit crashes on `Future<Result<AiAccess>>`.
    when(checkAiAccess.call)
        .thenAnswer((_) async => const Right(AiAccess.denied));
    getIt
      ..registerFactory<HomeCubit>(
        () => HomeCubit(
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
        ),
      )
      // `BilletudoApp` resolves `ThemeModeCubit` from `getIt` directly, not
      // through a provided widget tree — a fake avoids the real one's
      // `SharedPreferencesAsync` dependency reaching for a platform channel
      // that never resolves under `flutter test`.
      ..registerFactory<ThemeModeCubit>(() {
        final cubit = _MockThemeModeCubit();
        when(() => cubit.state).thenReturn(ThemeMode.system);
        whenListen(
          cubit,
          const Stream<ThemeMode>.empty(),
          initialState: ThemeMode.system,
        );
        when(cubit.load).thenAnswer((_) async {});
        return cubit;
      })
      // La rama `/inicio` provee `AppSettingsCubit` junto a `HomeCubit` desde
      // que el orden del acceso rápido es configurable: sin registrarlo, el
      // arranque revienta con "not registered inside GetIt" al construir Home.
      ..registerFactory<AppSettingsCubit>(() {
        final cubit = _MockAppSettingsCubit();
        when(() => cubit.state).thenReturn(const AppSettingsState());
        whenListen(
          cubit,
          const Stream<AppSettingsState>.empty(),
          initialState: const AppSettingsState(),
        );
        when(cubit.start).thenAnswer((_) async {});
        return cubit;
      });
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
