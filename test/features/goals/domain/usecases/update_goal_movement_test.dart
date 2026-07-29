import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal_movement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_repository_mock.dart';

GoalContribution _movement({
  String id = 'm1',
  String goalId = 'g1',
  int amountMinor = 5000,
  GoalMovementDirection direction = GoalMovementDirection.contribution,
  String? transactionId,
}) =>
    GoalContribution(
      id: id,
      goalId: goalId,
      amountMinor: amountMinor,
      direction: direction,
      date: DateTime(2026, 7, 10),
      transactionId: transactionId,
      createdAt: DateTime(2026, 7, 10),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository repository;
  late UpdateGoalMovement usecase;

  setUpAll(registerGoalRepositoryFallbacks);

  setUp(() {
    repository = MockGoalRepository();
    usecase = UpdateGoalMovement(repository);
  });

  test('rejects a non-positive amount without touching the repository',
      () async {
    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 0,
      date: DateTime(2026, 7, 10),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalContributionDraft.fieldAmountMinor,
    );
    verifyNever(() => repository.getContribution(any()));
    verifyNever(
      () => repository.updateContribution(
        contributionId: any(named: 'contributionId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    );
  });

  test('passes through a failure reading the movement (e.g. NotFoundFailure)',
      () async {
    when(() => repository.getContribution('m1')).thenAnswer(
      (_) async =>
          const Left(NotFoundFailure('contribution "m1" does not exist')),
    );

    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 1000,
      date: DateTime(2026, 7, 10),
    );

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('rejects editing a money-moving movement (transactionId != null)',
      () async {
    when(() => repository.getContribution('m1')).thenAnswer(
      (_) async => Right(_movement(transactionId: 'tx1')),
    );

    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 1000,
      date: DateTime(2026, 7, 10),
    );

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.getSavedMinor(any()));
    verifyNever(
      () => repository.updateContribution(
        contributionId: any(named: 'contributionId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    );
  });

  test('edits a tracking-only aporte, persisting the new amount/date/note',
      () async {
    when(() => repository.getContribution('m1')).thenAnswer(
      (_) async => Right(_movement(amountMinor: 5000)),
    );
    // savedMinor already reflects the OLD amount (5000).
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(20000));
    when(
      () => repository.updateContribution(
        contributionId: any(named: 'contributionId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 9000,
      date: DateTime(2026, 7, 15),
      note: '  regalo de cumpleaños  ',
    );

    expect(result.isRight(), isTrue);
    final captured = verify(
      () => repository.updateContribution(
        contributionId: captureAny(named: 'contributionId'),
        amountMinor: captureAny(named: 'amountMinor'),
        date: captureAny(named: 'date'),
        note: captureAny(named: 'note'),
      ),
    ).captured;
    expect(captured[0], 'm1');
    expect(captured[1], 9000);
    expect(captured[2], DateTime(2026, 7, 15));
    expect(captured[3], 'regalo de cumpleaños');
  });

  test(
      'edits a tracking-only retiro within the derived savedMinor, excluding '
      'its own previous amount from the check', () async {
    // Old withdrawal amount was 3000, already subtracted into savedMinor
    // (7000 = 10000 saved before this movement - 3000 old withdrawal).
    when(() => repository.getContribution('m1')).thenAnswer(
      (_) async => Right(
        _movement(
          amountMinor: 3000,
          direction: GoalMovementDirection.withdrawal,
        ),
      ),
    );
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(7000));
    when(
      () => repository.updateContribution(
        contributionId: any(named: 'contributionId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    // Excluding the old 3000: base saved is 10000. A new withdrawal of
    // exactly 10000 is the boundary and must be allowed.
    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 10000,
      date: DateTime(2026, 7, 10),
    );

    expect(result.isRight(), isTrue);
  });

  test(
      'rejects growing a retiro past the point where savedMinor would go '
      'negative, without persisting anything', () async {
    when(() => repository.getContribution('m1')).thenAnswer(
      (_) async => Right(
        _movement(
          amountMinor: 3000,
          direction: GoalMovementDirection.withdrawal,
        ),
      ),
    );
    when(() => repository.getSavedMinor('g1'))
        .thenAnswer((_) async => const Right(7000));

    // Base saved excluding this movement is 10000; asking to withdraw 10001
    // would leave savedMinor at -1.
    final result = await usecase(
      contributionId: 'm1',
      amountMinor: 10001,
      date: DateTime(2026, 7, 10),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalContributionDraft.fieldAmountMinor,
    );
    verifyNever(
      () => repository.updateContribution(
        contributionId: any(named: 'contributionId'),
        amountMinor: any(named: 'amountMinor'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    );
  });
}
