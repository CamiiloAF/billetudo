import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_repository_mock.dart';

Goal _goal({
  String id = 'g1',
  String currency = 'COP',
  String? accountId,
  DateTime? archivedAt,
}) =>
    Goal(
      id: id,
      name: 'Meta',
      targetMinor: 100000,
      currency: currency,
      accountId: accountId,
      archivedAt: archivedAt,
      lastMilestonePct: 0,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

GoalContribution _movement() => GoalContribution(
      id: 'm1',
      goalId: 'g1',
      amountMinor: 5000,
      direction: GoalMovementDirection.withdrawal,
      date: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository repository;
  late WithdrawFromGoal usecase;

  setUpAll(registerGoalRepositoryFallbacks);

  setUp(() {
    repository = MockGoalRepository();
    usecase = WithdrawFromGoal(repository);
  });

  test('rejects a withdrawal against an archived goal (HU-09)', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(archivedAt: DateTime(2026))));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 1000,
      date: DateTime(2026),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.withdraw(any()));
  });

  test('moving money out of a goal with no linked account is rejected',
      () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(accountId: null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 1000,
      date: DateTime(2026),
      moveMoney: true,
      destinationAccountId: 'acc1',
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalContributionDraft.fieldOriginAccountId,
    );
    verifyNever(() => repository.withdraw(any()));
  });

  test(
      'a withdrawal amount above the derived savedMinor is rejected as a '
      'domain invariant, not just a UI clamp (HU-04)', () async {
    when(() => repository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(3000));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 3001,
      date: DateTime(2026),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalContributionDraft.fieldAmountMinor,
    );
    verifyNever(() => repository.withdraw(any()));
  });

  test('a withdrawal of exactly the savedMinor is allowed (boundary)',
      () async {
    when(() => repository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(3000));
    when(() => repository.withdraw(any()))
        .thenAnswer((_) async => Right((_movement(), null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 3000,
      date: DateTime(2026),
    );

    expect(result.isRight(), isTrue);
  });

  test(
      'a money-moving withdrawal resolves origin as the goal\'s account and '
      'destination as the picked account', () async {
    when(() => repository.getGoal('g1')).thenAnswer(
      (_) async => Right(_goal(accountId: 'goal-account')),
    );
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(10000));
    when(() => repository.withdraw(any()))
        .thenAnswer((_) async => Right((_movement(), null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 1000,
      date: DateTime(2026),
      moveMoney: true,
      destinationAccountId: 'dest-account',
    );

    expect(result.isRight(), isTrue);
    final captured = verify(() => repository.withdraw(captureAny()))
        .captured
        .single as GoalContributionDraft;
    expect(captured.originAccountId, 'goal-account');
    expect(captured.destinationAccountId, 'dest-account');
    expect(captured.direction, GoalMovementDirection.withdrawal);
  });
}
