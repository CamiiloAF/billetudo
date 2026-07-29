import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_amount_hero_field.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden_helpers.dart';

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

/// Real `GoalContributionCubit`, no mock: reproduces the "Usar todo" flow the
/// way the app actually renders it, so this catches the bug a `MockCubit`
/// golden (fixed state, never rebuilt) can't — tapping the CTA has to both
/// update `state.amountMinor` *and* make `GoalAmountHeroField`'s own
/// `TextField` repaint with the new value, not just leave it at `$0`.
void main() {
  late MockWatchAccounts watchAccounts;

  setUp(() {
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(const Right<Failure, List<AccountWithBalance>>([])),
    );
  });

  GoalContributionCubit buildCubit() => GoalContributionCubit(
        MockContributeToGoal(),
        MockWithdrawFromGoal(),
        watchAccounts,
      );

  testWidgets(
    'tocar "Usar todo" actualiza el texto visible del campo de monto',
    (tester) async {
      final cubit = buildCubit();
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 500000,
        hasLinkedAccount: false,
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

      final amountFieldFinder = find.descendant(
        of: find.byType(GoalAmountHeroField),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(amountFieldFinder).controller!.text,
        '',
      );

      await tester.tap(find.byKey(const ValueKey('goal-withdraw-use-max')));
      await tester.pumpAndSettle();

      expect(cubit.state.amountMinor, 500000);
      expect(
        tester.widget<TextField>(amountFieldFinder).controller!.text,
        '5.000',
      );

      await cubit.close();
    },
  );

  testWidgets(
    'tapping the passive "Disponible en la meta" text does not trigger '
    'useMax — only the "Usar todo" CTA is tappable',
    (tester) async {
      final cubit = buildCubit();
      await cubit.start(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 500000,
        hasLinkedAccount: false,
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

      final availableLabelFinder = find.textContaining('Disponible en la meta');
      expect(availableLabelFinder, findsOneWidget);
      // The passive label sits outside any tappable ancestor (no
      // GestureDetector/InkWell/TextButton wraps it) — only the separate
      // "Usar todo" CTA does.
      expect(
        find.ancestor(
          of: availableLabelFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is GestureDetector ||
                widget is InkWell ||
                widget is TextButton,
          ),
        ),
        findsNothing,
      );

      await tester.tap(availableLabelFinder);
      await tester.pumpAndSettle();

      expect(cubit.state.amountMinor, 0);
      expect(
        tester.widget<TextField>(amountFieldFinder(tester)).controller!.text,
        '',
      );

      await cubit.close();
    },
  );
}

Finder amountFieldFinder(WidgetTester tester) => find.descendant(
      of: find.byType(GoalAmountHeroField),
      matching: find.byType(TextField),
    );
