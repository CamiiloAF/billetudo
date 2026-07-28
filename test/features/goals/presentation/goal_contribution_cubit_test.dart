import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

GoalContribution _movement({
  GoalMovementDirection direction = GoalMovementDirection.contribution,
  int amountMinor = 50000,
}) =>
    GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: amountMinor,
      direction: direction,
      date: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
    );

void main() {
  late MockContributeToGoal contribute;
  late MockWithdrawFromGoal withdraw;

  setUp(() {
    contribute = MockContributeToGoal();
    withdraw = MockWithdrawFromGoal();
  });

  GoalContributionCubit build() => GoalContributionCubit(contribute, withdraw);

  blocTest<GoalContributionCubit, GoalContributionState>(
    'un aporte exitoso queda saved y expone el hito cruzado',
    setUp: () => when(
      () => contribute(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right((_movement(), 50))),
    build: build,
    act: (cubit) {
      cubit.start(
        goalId: 'g1',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
      );
      cubit.amountChanged(50000);
      return cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<GoalContributionState>()
          .having((s) => s.status, 'status', GoalContributionStatus.saved)
          .having((s) => s.milestoneCrossed, 'milestoneCrossed', 50),
    ],
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'un retiro que excede el máximo no habilita el submit (canSubmit)',
    build: build,
    act: (cubit) {
      cubit.start(
        goalId: 'g1',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 10000,
      );
      cubit.amountChanged(20000);
    },
    verify: (cubit) => expect(cubit.state.canSubmit, isFalse),
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'useMax limita el monto al máximo retirable',
    build: build,
    act: (cubit) {
      cubit.start(
        goalId: 'g1',
        direction: GoalMovementDirection.withdrawal,
        currency: 'COP',
        maxWithdrawableMinor: 30000,
      );
      cubit.useMax();
    },
    verify: (cubit) => expect(cubit.state.amountMinor, 30000),
  );

  blocTest<GoalContributionCubit, GoalContributionState>(
    'una falla del caso de uso lleva a failure',
    setUp: () => when(
      () => contribute(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Left(ValidationFailure('boom'))),
    build: build,
    act: (cubit) {
      cubit.start(
        goalId: 'g1',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
      );
      cubit.amountChanged(50000);
      return cubit.submit();
    },
    skip: 3,
    expect: () => [
      isA<GoalContributionState>()
          .having((s) => s.status, 'status', GoalContributionStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );
}
