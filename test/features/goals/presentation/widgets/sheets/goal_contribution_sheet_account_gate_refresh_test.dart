import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/toggle_field.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/fake_note_suggestions.dart';
import '../../../../../support/golden_helpers.dart';
import '../../../../accounts/account_fixtures.dart';

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// Bug 1 (`docs/dev-runs/...`, reported against `goal_contribution_sheet
/// .dart`): turning "¿Mover dinero de una cuenta?" ON with zero accounts
/// opens the account gate bridge; creating an account from it used to leave
/// the sheet's account list stale, so the toggle turned on but the picker it
/// revealed had nothing to show. This pins the fix
/// (`GoalContributionCubit.refreshAccounts()`) end to end, through the same
/// real navigation the gate performs (`AppRoutes.newAccount` push/pop) —
/// which also exercises Bug 2's navigator-state concern: the sheet must
/// still be the one visible, correctly updated, once the account-creation
/// route pops.
void main() {
  late MockContributeToGoal contribute;
  late MockWithdrawFromGoal withdraw;
  late MockWatchAccounts watchAccounts;
  late StreamController<bool> hasAnyController;

  final account = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Nequi'),
    balanceMinor: 0,
  );

  setUp(() {
    contribute = MockContributeToGoal();
    withdraw = MockWithdrawFromGoal();
    watchAccounts = MockWatchAccounts();
    registerFakeNoteSuggestions();

    var call = 0;
    when(() => watchAccounts()).thenAnswer((_) {
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

  GoalContributionCubit buildCubit() =>
      GoalContributionCubit(contribute, withdraw, watchAccounts);

  Future<void> pumpApp(WidgetTester tester, GoalContributionCubit cubit) async {
    setGoldenViewport(tester, tallGoldenPhoneSize(height: 1600));
    final router = GoRouter(
      initialLocation: '/metas/aporte',
      routes: [
        GoRoute(
          path: '/metas',
          builder: (context, state) => const Scaffold(body: Text('metas')),
          routes: [
            GoRoute(
              path: 'aporte',
              builder: (context, state) =>
                  BlocProvider<GoalContributionCubit>.value(
                value: cubit,
                child: Scaffold(
                  body: BlocBuilder<GoalContributionCubit,
                      GoalContributionState>(
                    builder: (context, state) =>
                        GoalContributionSheetBody(state: state),
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
    await cubit.start(
      goalId: 'g1',
      goalName: 'Viaje a Cartagena',
      direction: GoalMovementDirection.contribution,
      currency: 'COP',
      hasLinkedAccount: true,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'crear una cuenta desde el puente refresca la lista y el toggle '
    'revela el picker con la cuenta nueva, sin cerrar y reabrir el sheet',
    (tester) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await pumpApp(tester, cubit);

      expect(cubit.state.moveMoney, isFalse);
      expect(find.text('Nequi'), findsNothing);

      await tester.tap(find.byType(ToggleField).first);
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

      // Bug 2 check: the navigator lands back on the aporte sheet's own
      // route, not stuck on the account-creation screen nor duplicated.
      expect(find.text('simulate-create'), findsNothing);
      expect(find.byType(GoalContributionSheetBody), findsOneWidget);

      // Bug 1 check: the toggle is now on and its picker reflects the
      // newly-created account without needing to close/reopen the sheet.
      expect(cubit.state.moveMoney, isTrue);
      expect(cubit.state.accounts, hasLength(1));
    },
  );
}
