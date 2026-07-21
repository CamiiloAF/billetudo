import 'package:billetudo/app.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_status_repository.dart';
import 'package:billetudo/core/sync/domain/usecases/get_pending_upload_count.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status.dart';
import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/entities/sign_out_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out_with_local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/watch_global_monthly_budget_progress.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockThemeModeCubit extends MockCubit<ThemeMode> implements ThemeModeCubit {}

class MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockWatchSyncStatus extends Mock implements WatchSyncStatus {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockWatchGlobalMonthlyBudgetProgress extends Mock
    implements WatchGlobalMonthlyBudgetProgress {}

class MockSignOut extends Mock implements SignOut {}

class MockSignOutWithLocalDataChoice extends Mock
    implements SignOutWithLocalDataChoice {}

class FakeSyncStatusRepository implements SyncStatusRepository {
  @override
  FutureResult<int> pendingUploadCount() async => const Right(0);

  @override
  Stream<SyncState> watchSyncState() => const Stream<SyncState>.empty();
}

/// HU-06 de punta a punta por la ruta real: el router es quien traduce cada
/// [SignOutOutcome] en lo que ve el usuario, y `_confirmSignOut` es privado,
/// asi que la unica forma de cubrirlo es recorriendo "Mas" → hoja → snackbar.
void main() {
  late MockSignOutWithLocalDataChoice signOutWithChoice;

  const signedIn = AuthSession.signedIn(
    AuthUser(
      id: 'user-1',
      displayName: 'Ana',
      provider: AuthProvider.google,
    ),
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(LocalDataChoice.keep);
  });

  // `BilletudoApp` resolves `ThemeModeCubit` from `getIt` directly (not
  // through a provided widget tree), so it needs a fake registered here too
  // — real `ThemeModeCubit` would reach for `SharedPreferencesAsync`'s
  // platform channel, which never resolves under `flutter test`.
  ThemeModeCubit fakeThemeModeCubit() {
    final cubit = MockThemeModeCubit();
    when(() => cubit.state).thenReturn(ThemeMode.system);
    whenListen(
      cubit,
      const Stream<ThemeMode>.empty(),
      initialState: ThemeMode.system,
    );
    when(cubit.load).thenAnswer((_) async {});
    return cubit;
  }

  setUp(() {
    final watchAccounts = MockWatchAccounts();
    final watchMonthTransactions = MockWatchMonthTransactions();
    final watchAuthSession = MockWatchAuthSession();
    final watchSyncStatus = MockWatchSyncStatus();
    final restoreTransaction = MockRestoreTransaction();
    final watchGlobalMonthlyBudgetProgress =
        MockWatchGlobalMonthlyBudgetProgress();
    when(watchAccounts.call).thenAnswer(
      (_) => const Stream<Result<List<AccountWithBalance>>>.empty(),
    );
    when(() => watchMonthTransactions(any())).thenAnswer(
      (_) => const Stream<Result<List<TransactionWithDetails>>>.empty(),
    );
    when(watchSyncStatus.call).thenAnswer((_) => const Stream<SyncState>.empty());
    // La fila "Cerrar sesión" de Más solo existe con sesión iniciada.
    when(watchAuthSession.call).thenAnswer(
      (_) => const Stream<AuthSession>.empty(),
    );
    when(() => watchAuthSession.current).thenReturn(signedIn);
    when(watchGlobalMonthlyBudgetProgress.call).thenAnswer(
      (_) => const Stream<Result<BudgetWithProgress?>>.empty(),
    );

    signOutWithChoice = MockSignOutWithLocalDataChoice();

    getIt
      ..registerFactory<HomeCubit>(
        () => HomeCubit(
          watchAccounts,
          watchMonthTransactions,
          watchAuthSession,
          watchSyncStatus,
          restoreTransaction,
          watchGlobalMonthlyBudgetProgress,
        ),
      )
      ..registerFactory<AuthCubit>(
        () => AuthCubit(watchAuthSession, MockSignOut()),
      )
      ..registerFactory<SignOutSheetCubit>(
        () => SignOutSheetCubit(
          GetPendingUploadCount(FakeSyncStatusRepository()),
        ),
      )
      ..registerFactory<SignOutWithLocalDataChoice>(() => signOutWithChoice)
      ..registerFactory<ThemeModeCubit>(fakeThemeModeCubit);
  });

  tearDown(getIt.reset);

  /// Arranca la app en español, entra a "Más", abre la hoja de cerrar sesión
  /// y confirma con la opción por defecto (`keep`).
  Future<void> signOutFromMore(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    tester.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const BilletudoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Más').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();

    // CTA de la hoja: el título homónimo queda arriba, el botón es el último.
    await tester.tap(
      find
          .descendant(
            of: find.byType(ConfirmSignOutSheet),
            matching: find.text('Cerrar sesión'),
          )
          .last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'SignOutFailed avisa que no se borró nada, para que reintentar sea lo '
    'obvio',
    (tester) async {
      when(() => signOutWithChoice(any())).thenAnswer(
        (_) async => const SignOutFailed(NetworkFailure('sin red')),
      );

      await signOutFromMore(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'No pudimos cerrar tu sesión, así que no borramos nada de este '
          'teléfono. Inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SignedOutButWipeFailed sigue teniendo su propio mensaje, distinto al de '
    'SignOutFailed',
    (tester) async {
      when(() => signOutWithChoice(any())).thenAnswer(
        (_) async =>
            const SignedOutButWipeFailed(DatabaseFailure('no se pudo borrar')),
      );

      await signOutFromMore(tester);

      expect(
        find.text(
          'Cerramos tu sesión, pero no pudimos borrar los datos de este '
          'teléfono. Siguen aquí.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('un cierre de sesión exitoso no muestra ningún snackbar',
      (tester) async {
    when(() => signOutWithChoice(any())).thenAnswer(
      (_) async => const SignedOutKeepingData(),
    );

    await signOutFromMore(tester);

    expect(find.byType(SnackBar), findsNothing);
  });
}
