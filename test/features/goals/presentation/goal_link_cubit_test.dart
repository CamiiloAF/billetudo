import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/link_transaction_to_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_link_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_link_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLinkTransactionToGoal extends Mock implements LinkTransactionToGoal {}

GoalContribution _movement() => GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: 20000,
      direction: GoalMovementDirection.contribution,
      transactionId: 't9',
      date: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1).millisecondsSinceEpoch,
    );

void main() {
  late MockLinkTransactionToGoal linkTransactionToGoal;

  setUpAll(() {
    registerFallbackValue(GoalMovementDirection.contribution);
  });

  setUp(() => linkTransactionToGoal = MockLinkTransactionToGoal());

  GoalLinkCubit build() => GoalLinkCubit(linkTransactionToGoal)
    ..start(
      goalId: 'g1',
      goalName: 'Viaje a Cartagena',
      direction: GoalMovementDirection.contribution,
    );

  test('link exitoso devuelve true y atribuye la transacción a la meta',
      () async {
    when(
      () => linkTransactionToGoal.call(
        goalId: any(named: 'goalId'),
        transactionId: any(named: 'transactionId'),
        direction: any(named: 'direction'),
      ),
    ).thenAnswer((_) async => Right(_movement()));

    final cubit = build();
    final linked = await cubit.link('t9');

    expect(linked, isTrue);
    expect(cubit.state.status, GoalLinkStatus.idle);
    verify(
      () => linkTransactionToGoal.call(
        goalId: 'g1',
        transactionId: 't9',
        direction: GoalMovementDirection.contribution,
      ),
    ).called(1);
  });

  test('link fallido devuelve false y expone la falla', () async {
    when(
      () => linkTransactionToGoal.call(
        goalId: any(named: 'goalId'),
        transactionId: any(named: 'transactionId'),
        direction: any(named: 'direction'),
      ),
    ).thenAnswer((_) async => const Left(UnexpectedFailure('nope')));

    final cubit = build();
    final linked = await cubit.link('t9');

    expect(linked, isFalse);
    expect(cubit.state.status, GoalLinkStatus.failure);
  });
}
