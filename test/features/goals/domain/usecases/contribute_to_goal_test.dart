import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
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
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository repository;
  late ContributeToGoal usecase;

  setUpAll(registerGoalRepositoryFallbacks);

  setUp(() {
    repository = MockGoalRepository();
    usecase = ContributeToGoal(repository);
  });

  test('rejects a contribution against an archived goal (HU-09)', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(archivedAt: DateTime(2026))));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 5000,
      date: DateTime(2026),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.contribute(any()));
  });

  test('moving money into a goal with no linked account is rejected',
      () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(accountId: null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 5000,
      date: DateTime(2026),
      moveMoney: true,
      sourceAccountId: 'acc1',
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalContributionDraft.fieldDestinationAccountId,
    );
    verifyNever(() => repository.contribute(any()));
  });

  test(
      'a tracking-only contribution builds a draft with no account/currency '
      'mismatch and the goal\'s own currency', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(currency: 'USD')));
    when(() => repository.contribute(any()))
        .thenAnswer((_) async => Right((_movement(), null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 5000,
      date: DateTime(2026),
    );

    expect(result.isRight(), isTrue);
    final captured = verify(() => repository.contribute(captureAny()))
        .captured
        .single as GoalContributionDraft;
    expect(captured.moveMoney, isFalse);
    expect(captured.originAccountId, isNull);
    expect(captured.destinationAccountId, isNull);
    expect(captured.currency, 'USD');
    expect(captured.direction, GoalMovementDirection.contribution);
  });

  test(
      'a money-moving contribution resolves origin/destination from the '
      'picked account and the goal\'s linked account', () async {
    when(() => repository.getGoal('g1')).thenAnswer(
      (_) async => Right(_goal(accountId: 'goal-account')),
    );
    when(() => repository.contribute(any()))
        .thenAnswer((_) async => Right((_movement(), null)));

    final result = await usecase(
      goalId: 'g1',
      amountMinor: 5000,
      date: DateTime(2026),
      moveMoney: true,
      sourceAccountId: 'source-account',
    );

    expect(result.isRight(), isTrue);
    final captured = verify(() => repository.contribute(captureAny()))
        .captured
        .single as GoalContributionDraft;
    expect(captured.originAccountId, 'source-account');
    expect(captured.destinationAccountId, 'goal-account');
  });
}
