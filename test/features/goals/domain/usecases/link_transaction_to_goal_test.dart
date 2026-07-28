import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/link_transaction_to_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_repository_mock.dart';

Goal _goal({DateTime? archivedAt}) => Goal(
      id: 'g1',
      name: 'Meta',
      targetMinor: 100000,
      currency: 'COP',
      archivedAt: archivedAt,
      lastMilestonePct: 0,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

GoalContribution _movement() => GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: 5000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026),
      transactionId: 'tx1',
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository repository;
  late LinkTransactionToGoal usecase;

  setUpAll(registerGoalRepositoryFallbacks);

  setUp(() {
    repository = MockGoalRepository();
    usecase = LinkTransactionToGoal(repository);
  });

  test('rejects linking a transaction to an archived goal', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(archivedAt: DateTime(2026))));

    final result = await usecase(
      goalId: 'g1',
      transactionId: 'tx1',
      direction: GoalMovementDirection.contribution,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.linkExistingTransaction(
        goalId: any(named: 'goalId'),
        transactionId: any(named: 'transactionId'),
        direction: any(named: 'direction'),
      ),
    );
  });

  test('links an existing transaction to an active goal', () async {
    when(() => repository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(
      () => repository.linkExistingTransaction(
        goalId: 'g1',
        transactionId: 'tx1',
        direction: GoalMovementDirection.contribution,
        note: null,
      ),
    ).thenAnswer((_) async => Right(_movement()));

    final result = await usecase(
      goalId: 'g1',
      transactionId: 'tx1',
      direction: GoalMovementDirection.contribution,
    );

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()!.transactionId, 'tx1');
  });
}
