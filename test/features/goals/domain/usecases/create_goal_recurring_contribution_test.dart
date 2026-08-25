import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_recurring_contribution.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_scheduled_payment.dart';
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
  late CreateGoalRecurringContribution usecase;

  setUpAll(() {
    registerGoalRepositoryFallbacks();
    registerScheduledPaymentFallbacks();
  });

  setUp(() {
    goalRepository = MockGoalRepository();
    scheduledPaymentRepository = MockScheduledPaymentRepository();
    usecase = CreateGoalRecurringContribution(
      goalRepository,
      CreateScheduledPayment(scheduledPaymentRepository),
    );
  });

  test('rejects creating a recurring contribution for an archived goal',
      () async {
    when(() => goalRepository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(archivedAt: DateTime(2026))));

    final result = await usecase(
      goalId: 'g1',
      accountId: 'acc-1',
      amountMinor: 50000,
      currency: 'COP',
      frequency: ScheduledPaymentFrequency.monthly,
      nextDate: DateTime(2026, 8, 1),
      categoryId: 'cat-savings',
      categoryKind: null,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => scheduledPaymentRepository.createScheduledPayment(any()));
  });

  test('creates an expense template linked to the goal via goalId', () async {
    when(() => goalRepository.getGoal('g1')).thenAnswer((_) async => Right(_goal()));
    when(() => scheduledPaymentRepository.createScheduledPayment(any()))
        .thenAnswer(
      (invocation) async => Right(
        buildScheduledPayment(
          id: 'sp-1',
          goalId: 'g1',
          type: ScheduledPaymentType.expense,
        ),
      ),
    );

    final result = await usecase(
      goalId: 'g1',
      accountId: 'acc-1',
      amountMinor: 50000,
      currency: 'COP',
      frequency: ScheduledPaymentFrequency.monthly,
      nextDate: DateTime(2026, 8, 1),
      categoryId: 'cat-savings',
      categoryKind: CategoryKind.expense,
    );

    expect(result.isRight(), isTrue);
    final captured = verify(
      () => scheduledPaymentRepository.createScheduledPayment(captureAny()),
    ).captured.single as ScheduledPaymentDraft;
    expect(captured.goalId, 'g1');
    expect(captured.debtId, isNull);
    expect(captured.type, ScheduledPaymentType.expense);
    expect(captured.accountId, 'acc-1');
    expect(captured.amountMinor, 50000);
  });
}
