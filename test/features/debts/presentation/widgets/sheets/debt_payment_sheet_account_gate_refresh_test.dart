import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/preferences/debt_payment_toggle_preference_datasource.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_ledger_event.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_cash_switch.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/fake_note_suggestions.dart';
import '../../../../../support/golden_helpers.dart';
import '../../../../accounts/account_fixtures.dart';
import '../../debts_presentation_fixtures.dart';

class MockRegisterDebtCashEvent extends Mock implements RegisterDebtCashEvent {}

class MockRegisterDebtLedgerEvent extends Mock
    implements RegisterDebtLedgerEvent {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockTogglePreference extends Mock
    implements DebtPaymentTogglePreferenceDatasource {}

class MockGetCategory extends Mock implements GetCategory {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// Bug 1 (`docs/dev-runs/...`, reported against `debt_payment_sheet.dart`):
/// turning "¿Agregar a una cuenta?" ON with zero accounts opens the account
/// gate bridge; creating an account from it used to leave the sheet's
/// account list stale, so the switch/selector looked "stuck" until the sheet
/// was closed and reopened. This pins the fix (`DebtPaymentCubit
/// .refreshAccounts()`) end to end, through the same real navigation the
/// gate performs (`AppRoutes.newAccount` push/pop) — which also exercises
/// Bug 2's navigator-state concern: the sheet must still be the one visible,
/// correctly updated, once the account-creation route pops.
void main() {
  late MockRegisterDebtCashEvent registerCashEvent;
  late MockRegisterDebtLedgerEvent registerLedgerEvent;
  late MockWatchAccounts watchAccounts;
  late MockTogglePreference togglePreference;
  late MockGetCategory getCategory;
  late StreamController<bool> hasAnyController;

  final account = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Ahorros'),
    balanceMinor: 0,
  );

  setUp(() {
    registerCashEvent = MockRegisterDebtCashEvent();
    registerLedgerEvent = MockRegisterDebtLedgerEvent();
    watchAccounts = MockWatchAccounts();
    togglePreference = MockTogglePreference();
    getCategory = MockGetCategory();
    registerFakeNoteSuggestions();

    when(() => togglePreference.readAddToAccount(any()))
        .thenAnswer((_) async => true);
    when(() => togglePreference.writeAddToAccount(
          debtId: any(named: 'debtId'),
          addToAccount: any(named: 'addToAccount'),
        )).thenAnswer((_) async {});
    when(() => getCategory(any())).thenAnswer((_) async => const Left(
          NotFoundFailure('categoría no encontrada'),
        ));

    var call = 0;
    when(watchAccounts.call).thenAnswer((_) {
      call += 1;
      return Stream.value(
        Right(call == 1 ? const <AccountWithBalance>[] : [account]),
      );
    });

    hasAnyController = StreamController<bool>.broadcast();
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => hasAnyController.stream);
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call).thenAnswer(
      (_) => hasAnyController.stream.map((hasAny) => hasAny ? 1 : 0),
    );
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  });

  tearDown(getIt.reset);
  tearDown(() => hasAnyController.close());

  DebtPaymentCubit buildCubit() => DebtPaymentCubit(
        registerCashEvent,
        registerLedgerEvent,
        watchAccounts,
        togglePreference,
        getCategory,
      );

  Future<GoRouter> pumpApp(WidgetTester tester, DebtPaymentCubit cubit) async {
    setGoldenViewport(tester, tallGoldenPhoneSize(height: 1600));
    final router = GoRouter(
      initialLocation: '/deudas/abono',
      routes: [
        GoRoute(
          path: '/deudas',
          builder: (context, state) => const Scaffold(body: Text('deudas')),
          routes: [
            GoRoute(
              path: 'abono',
              builder: (context, state) => BlocProvider<DebtPaymentCubit>.value(
                value: cubit,
                child: Scaffold(
                  body: BlocBuilder<DebtPaymentCubit, DebtPaymentState>(
                    builder: (context, state) => DebtPaymentSheetBody(
                      state: state,
                      onLinkExisting: () {},
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.newAccount,
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('simulate-create'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await cubit.start(buildDebt(name: 'Crédito vehicular'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'crear una cuenta desde el puente refresca la lista y el switch '
    'muestra la cuenta nueva, sin cerrar y reabrir el sheet',
    (tester) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await pumpApp(tester, cubit);

      // Starts with no accounts: the switch is off and the account row is
      // not shown yet.
      expect(cubit.state.addToAccount, isFalse);
      expect(find.text('Ahorros'), findsNothing);

      await tester.tap(find.byType(DebtCashSwitch));
      await tester.pump();
      hasAnyController.add(false);
      await tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      final bridgeContext = tester.element(find.byType(AccountGateBridgeSheet));
      final bridgeL10n = AppLocalizations.of(bridgeContext);
      await tester.tap(find.text(bridgeL10n.accountGateCreateAccount));
      await tester.pumpAndSettle();

      expect(find.text('simulate-create'), findsOneWidget);
      await tester.tap(find.text('simulate-create'));
      await tester.pump();
      hasAnyController.add(true);
      await tester.pumpAndSettle();

      // Bug 2 check: the navigator lands back on the abono sheet's own
      // route, not stuck on the account-creation screen nor duplicated.
      expect(find.text('simulate-create'), findsNothing);
      expect(find.byType(DebtPaymentSheetBody), findsOneWidget);

      // Bug 1 check: the switch is now on and the newly-created account
      // shows up without needing to close/reopen the sheet.
      expect(cubit.state.addToAccount, isTrue);
      expect(cubit.state.accounts, hasLength(1));
      expect(find.text('Ahorros'), findsOneWidget);
    },
  );
}
