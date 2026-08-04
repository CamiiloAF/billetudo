import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_quick_amounts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_quick_amounts_repository_mock.dart';

void main() {
  late MockGoalQuickAmountsRepository repository;
  late WatchGoalQuickAmounts watchGoalQuickAmounts;

  setUp(() {
    repository = MockGoalQuickAmountsRepository();
    watchGoalQuickAmounts = WatchGoalQuickAmounts(repository);
  });

  test('delega en el repositorio con el goalId', () async {
    final quickAmount = GoalQuickAmount(
      id: 'qa1',
      goalId: 'g1',
      amountMinor: 20000,
      createdAt: DateTime(2026, 7, 28),
      updatedAt: DateTime(2026, 7, 28).millisecondsSinceEpoch,
    );
    when(() => repository.watchQuickAmounts('g1'))
        .thenAnswer((_) => Stream.value(Right([quickAmount])));

    final result = await watchGoalQuickAmounts('g1').first;

    expect(result.getRight().toNullable(), [quickAmount]);
    verify(() => repository.watchQuickAmounts('g1')).called(1);
  });
}
