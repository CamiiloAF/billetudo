import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ValidationFailure failureOf(Result<GoalContributionDraft> result) =>
      result.getLeft().toNullable()! as ValidationFailure;

  GoalContributionDraft trackingOnly({int amountMinor = 50000}) =>
      GoalContributionDraft(
        goalId: 'goal-1',
        amountMinor: amountMinor,
        direction: GoalMovementDirection.contribution,
        date: DateTime(2026, 7, 1),
        currency: 'COP',
      );

  test('un aporte de seguimiento puro (sin mover dinero) no requiere cuenta', () {
    final result = trackingOnly().validated();

    expect(result.isRight(), isTrue);
    final draft = result.getRight().toNullable()!;
    expect(draft.moveMoney, isFalse);
    expect(draft.originAccountId, isNull);
    expect(draft.destinationAccountId, isNull);
  });

  test('rechaza un monto cero o negativo', () {
    for (final amount in [0, -100]) {
      final result = trackingOnly(amountMinor: amount).validated();

      expect(failureOf(result).field, GoalContributionDraft.fieldAmountMinor);
    }
  });

  test('mover dinero sin cuenta de origen se rechaza', () {
    final result = GoalContributionDraft(
      goalId: 'goal-1',
      amountMinor: 50000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026, 7, 1),
      currency: 'COP',
      moveMoney: true,
      destinationAccountId: 'acc-goal',
    ).validated();

    expect(
      failureOf(result).field,
      GoalContributionDraft.fieldOriginAccountId,
    );
  });

  test('mover dinero a la misma cuenta se rechaza', () {
    final result = GoalContributionDraft(
      goalId: 'goal-1',
      amountMinor: 50000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026, 7, 1),
      currency: 'COP',
      moveMoney: true,
      originAccountId: 'acc-1',
      destinationAccountId: 'acc-1',
    ).validated();

    expect(
      failureOf(result).field,
      GoalContributionDraft.fieldDestinationAccountId,
    );
  });

  test('countsInBudget requiere una categoría', () {
    final result = GoalContributionDraft(
      goalId: 'goal-1',
      amountMinor: 50000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026, 7, 1),
      currency: 'COP',
      moveMoney: true,
      originAccountId: 'acc-1',
      destinationAccountId: 'acc-goal',
      countsInBudget: true,
    ).validated();

    expect(failureOf(result).field, GoalContributionDraft.fieldCategoryId);
  });

  test('un movimiento presupuestable válido pasa con su categoría', () {
    final result = GoalContributionDraft(
      goalId: 'goal-1',
      amountMinor: 50000,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026, 7, 1),
      currency: 'COP',
      moveMoney: true,
      originAccountId: 'acc-1',
      destinationAccountId: 'acc-goal',
      countsInBudget: true,
      categoryId: 'seed-savings',
    ).validated();

    expect(result.isRight(), isTrue);
  });
}
