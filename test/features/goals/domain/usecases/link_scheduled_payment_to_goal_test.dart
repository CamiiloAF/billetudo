import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/usecases/link_scheduled_payment_to_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../scheduled_payments/domain/usecases/scheduled_payment_repository_mock.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';
import 'goal_repository_mock.dart';

Goal _goal({DateTime? archivedAt}) => Goal(
      id: 'g1',
      name: 'Vacaciones',
      targetMinor: 100000,
      currency: 'COP',
      archivedAt: archivedAt,
      lastMilestonePct: 0,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository goalRepository;
  late MockScheduledPaymentRepository scheduledPaymentRepository;
  late LinkScheduledPaymentToGoal usecase;

  setUpAll(registerGoalRepositoryFallbacks);

  setUp(() {
    goalRepository = MockGoalRepository();
    scheduledPaymentRepository = MockScheduledPaymentRepository();
    usecase =
        LinkScheduledPaymentToGoal(goalRepository, scheduledPaymentRepository);
  });

  test('rejects linking to an archived goal', () async {
    when(() => goalRepository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(archivedAt: DateTime(2026))));

    final result = await usecase(goalId: 'g1', scheduledPaymentId: 'sp-1');

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => scheduledPaymentRepository.getScheduledPayment(any()),
    );
  });

  test('rejects a template that already has a debtId', () async {
    when(() => goalRepository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => scheduledPaymentRepository.getScheduledPayment('sp-1'))
        .thenAnswer(
      (_) async => Right(buildScheduledPayment(id: 'sp-1', debtId: 'debt-1')),
    );

    final result = await usecase(goalId: 'g1', scheduledPaymentId: 'sp-1');

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => scheduledPaymentRepository.linkScheduledPaymentToGoal(
        scheduledPaymentId: any(named: 'scheduledPaymentId'),
        goalId: any(named: 'goalId'),
      ),
    );
  });

  test('rejects a template that already has a goalId', () async {
    when(() => goalRepository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => scheduledPaymentRepository.getScheduledPayment('sp-1'))
        .thenAnswer(
      (_) async =>
          Right(buildScheduledPayment(id: 'sp-1', goalId: 'other-goal')),
    );

    final result = await usecase(goalId: 'g1', scheduledPaymentId: 'sp-1');

    expect(result.isLeft(), isTrue);
  });

  test('links an eligible template to the goal', () async {
    when(() => goalRepository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => scheduledPaymentRepository.getScheduledPayment('sp-1'))
        .thenAnswer((_) async => Right(buildScheduledPayment(id: 'sp-1')));
    when(
      () => scheduledPaymentRepository.linkScheduledPaymentToGoal(
        scheduledPaymentId: 'sp-1',
        goalId: 'g1',
      ),
    ).thenAnswer(
      (_) async => Right(buildScheduledPayment(id: 'sp-1', goalId: 'g1')),
    );

    final result = await usecase(goalId: 'g1', scheduledPaymentId: 'sp-1');

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()!.goalId, 'g1');
  });
}
