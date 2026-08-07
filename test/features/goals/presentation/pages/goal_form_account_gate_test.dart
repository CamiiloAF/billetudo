import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_detail.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';

class MockCreateGoal extends Mock implements CreateGoal {}

class MockUpdateGoal extends Mock implements UpdateGoal {}

class MockDeleteGoal extends Mock implements DeleteGoal {}

class MockWatchGoalDetail extends Mock implements WatchGoalDetail {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md`: "Cuenta vinculada" (`goal_form_page.dart`,
/// `_pickAccount`) went from a silent no-op with zero accounts to an
/// informative, non-blocking gate — this is what pins that contract:
/// tapping the field opens the bridge instead of doing nothing, cancelling
/// it leaves the form fully usable (creating the goal never depends on
/// having any account), and creating an account from the bridge refreshes
/// the list and opens the picker right away.
void main() {
  late MockCreateGoal createGoal;
  late MockUpdateGoal updateGoal;
  late MockDeleteGoal deleteGoal;
  late MockWatchGoalDetail watchGoalDetail;
  late MockWatchAccounts watchAccounts;
  late StreamController<bool> hasAnyController;

  setUp(() {
    createGoal = MockCreateGoal();
    updateGoal = MockUpdateGoal();
    deleteGoal = MockDeleteGoal();
    watchGoalDetail = MockWatchGoalDetail();
    watchAccounts = MockWatchAccounts();
    when(watchAccounts.call)
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
    registerFallbackValue(
      const GoalDraft(name: 'x', targetMinor: 1, currency: 'COP'),
    );

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

  GoalFormCubit buildCubit() => GoalFormCubit(
        createGoal,
        updateGoal,
        deleteGoal,
        watchGoalDetail,
        watchAccounts,
      );

  Future<GoRouter> pumpApp(WidgetTester tester, GoalFormCubit cubit) async {
    setGoldenViewport(tester, tallGoldenPhoneSize(height: 1400));
    final router = GoRouter(
      initialLocation: '/metas/meta',
      routes: [
        GoRoute(
          path: '/metas',
          builder: (context, state) => const Scaffold(body: Text('metas')),
          routes: [
            GoRoute(
              path: 'meta',
              builder: (context, state) => BlocProvider<GoalFormCubit>.value(
                value: cubit,
                child: const GoalFormPage(),
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
    await cubit.load(null);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
      'tocar "Cuenta vinculada" sin cuentas abre el puente, no es un no-op',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpApp(tester, cubit);

    await tester.tap(find.text('Elige una cuenta'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
  });

  testWidgets(
      'cancelar el puente ("Ahora no") no afecta poder crear la meta',
      (tester) async {
    when(() => createGoal(any())).thenAnswer(
      (_) async => Right(
        Goal(
          id: 'g1',
          name: 'Viaje',
          targetMinor: 500000,
          currency: 'COP',
          lastMilestonePct: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        ),
      ),
    );
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpApp(tester, cubit);

    await tester.tap(find.text('Elige una cuenta'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AccountGateBridgeSheet));
    final l10n = AppLocalizations.of(context);
    await tester.tap(find.text(l10n.accountGateNotNow));
    await tester.pumpAndSettle();

    // The bridge is gone and nothing in the form changed — no account got
    // linked.
    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(cubit.state.accountId, isNull);

    // Creating the goal still works with zero accounts: `submit()` never
    // reads `state.accounts`.
    cubit.nameChanged('Viaje');
    cubit.targetMinorChanged(500000);
    await cubit.submit();
    await tester.pumpAndSettle();
    verify(() => createGoal(any())).called(1);
  });

  testWidgets(
      'crear una cuenta desde el puente refresca la lista y abre el picker',
      (tester) async {
    final account = buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Ahorros'),
      balanceMinor: 0,
    );
    var call = 0;
    when(watchAccounts.call).thenAnswer((_) {
      call += 1;
      return Stream.value(
        Right(call == 1 ? const <AccountWithBalance>[] : [account]),
      );
    });

    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpApp(tester, cubit);

    await tester.tap(find.text('Elige una cuenta'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    final bridgeContext = tester.element(find.byType(AccountGateBridgeSheet));
    final bridgeL10n = AppLocalizations.of(bridgeContext);
    await tester.tap(find.text(bridgeL10n.accountGateCreateAccount));
    await tester.pumpAndSettle();

    expect(find.text('simulate-create'), findsOneWidget);
    await tester.tap(find.text('simulate-create'));
    await tester.pump();
    hasAnyController.add(true);
    await tester.pumpAndSettle();

    expect(cubit.state.accounts, hasLength(1));
    // The picker sheet opened right away with the freshly-refreshed list.
    expect(find.text('Ahorros'), findsOneWidget);
  });
}
