import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_quick_amount.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_quick_amounts_repository_mock.dart';

void main() {
  late MockGoalQuickAmountsRepository repository;
  late CreateGoalQuickAmount createGoalQuickAmount;

  setUp(() {
    repository = MockGoalQuickAmountsRepository();
    createGoalQuickAmount = CreateGoalQuickAmount(repository);
  });

  GoalQuickAmount buildQuickAmount() => GoalQuickAmount(
        id: 'qa1',
        goalId: 'g1',
        amountMinor: 20000,
        createdAt: DateTime(2026, 7, 28),
        updatedAt: DateTime(2026, 7, 28).millisecondsSinceEpoch,
      );

  test('crea un chip cuando el monto es válido', () async {
    when(
      () => repository.createQuickAmount(goalId: 'g1', amountMinor: 20000),
    ).thenAnswer((_) async => Right(buildQuickAmount()));

    final result =
        await createGoalQuickAmount(goalId: 'g1', amountMinor: 20000);

    expect(result.getRight().toNullable(), buildQuickAmount());
    verify(
      () => repository.createQuickAmount(goalId: 'g1', amountMinor: 20000),
    ).called(1);
  });

  test('rechaza un monto de 0 sin llamar al repositorio', () async {
    final result = await createGoalQuickAmount(goalId: 'g1', amountMinor: 0);

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.createQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    );
  });

  test('rechaza un monto negativo sin llamar al repositorio', () async {
    final result = await createGoalQuickAmount(goalId: 'g1', amountMinor: -100);

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.createQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    );
  });

  test('propaga el fallo del repositorio', () async {
    when(
      () => repository.createQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    ).thenAnswer((_) async => const Left(DatabaseFailure('disco lleno')));

    final result =
        await createGoalQuickAmount(goalId: 'g1', amountMinor: 20000);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
