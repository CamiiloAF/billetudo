import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
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
import 'package:mocktail/mocktail.dart';

import '../../../../../support/fake_note_suggestions.dart';
import '../../../../../support/golden_helpers.dart';

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md` HU-03/HU-10: turning the "¿Mover dinero de una
/// cuenta?" toggle to Sí on a goal with a linked account generates a real
/// transfer, so without any active account in the app it must open the
/// bridge (`AccountGateSurface.goalMovement`, `xU4uz`) instead of silently
/// revealing an account selector with nothing to pick.
void main() {
  late MockWatchAccounts watchAccounts;

  setUp(() {
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(const Right<Failure, List<AccountWithBalance>>([])),
    );
    registerFakeNoteSuggestions();
  });

  tearDown(getIt.reset);

  void registerAccountGate({required bool hasAny}) {
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => Stream.value(hasAny));
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call)
        .thenAnswer((_) => Stream.value(hasAny ? 1 : 0));
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  }

  GoalContributionCubit buildCubit() => GoalContributionCubit(
        MockContributeToGoal(),
        MockWithdrawFromGoal(),
        watchAccounts,
      );

  Future<GoalContributionCubit> pumpSheet(WidgetTester tester) async {
    final cubit = buildCubit();
    await cubit.start(
      goalId: 'g1',
      goalName: 'Viaje a Cartagena',
      direction: GoalMovementDirection.contribution,
      currency: 'COP',
      hasLinkedAccount: true,
    );

    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider<GoalContributionCubit>.value(
          value: cubit,
          child: BlocBuilder<GoalContributionCubit, GoalContributionState>(
            builder: (context, state) =>
                GoalContributionSheetBody(state: state),
          ),
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets(
    'sin ninguna cuenta activa, encender el toggle abre el puente en vez '
    'de revelar el selector de cuenta',
    (tester) async {
      registerAccountGate(hasAny: false);
      final cubit = await pumpSheet(tester);

      expect(cubit.state.moveMoney, isFalse);
      await tester.tap(find.byType(ToggleField).first);
      await tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      expect(cubit.state.moveMoney, isFalse);

      await cubit.close();
    },
  );

  testWidgets(
    'con al menos una cuenta activa, encender el toggle cambia el estado '
    'directo, sin puente',
    (tester) async {
      registerAccountGate(hasAny: true);
      final cubit = await pumpSheet(tester);

      await tester.tap(find.byType(ToggleField).first);
      await tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsNothing);
      expect(cubit.state.moveMoney, isTrue);

      await cubit.close();
    },
  );

  testWidgets(
    'apagar el toggle (ya encendido) nunca pasa por el gate',
    (tester) async {
      // Even with 0 active accounts in the app, turning an already-ON
      // toggle OFF never needs the gate (`_toggleMoveMoney` short-circuits
      // before calling `showAccountGateIfNeeded` for `value == false`).
      registerAccountGate(hasAny: true);
      final cubit = await pumpSheet(tester);

      // Turn it on first (allowed: there is an active account).
      await tester.tap(find.byType(ToggleField).first);
      await tester.pumpAndSettle();
      expect(cubit.state.moveMoney, isTrue);
      expect(find.byType(AccountGateBridgeSheet), findsNothing);

      // Turning it back off must not open the bridge either.
      await tester.tap(find.byType(ToggleField).first);
      await tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsNothing);
      expect(cubit.state.moveMoney, isFalse);

      await cubit.close();
    },
  );
}
