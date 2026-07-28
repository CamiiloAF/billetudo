import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/usecases/delete_goal_quick_amount.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goal_quick_amounts_repository_mock.dart';

void main() {
  late MockGoalQuickAmountsRepository repository;
  late DeleteGoalQuickAmount deleteGoalQuickAmount;

  setUp(() {
    repository = MockGoalQuickAmountsRepository();
    deleteGoalQuickAmount = DeleteGoalQuickAmount(repository);
  });

  test('delega en el repositorio', () async {
    when(() => repository.deleteQuickAmount('qa1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await deleteGoalQuickAmount('qa1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteQuickAmount('qa1')).called(1);
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.deleteQuickAmount('qa1')).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await deleteGoalQuickAmount('qa1');

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
