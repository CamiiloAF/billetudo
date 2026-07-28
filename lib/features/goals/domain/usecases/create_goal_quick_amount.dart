import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_quick_amount.dart';
import '../repositories/goal_quick_amounts_repository.dart';

/// Creates a new "aporte rápido" chip for a goal — the "+ Nueva" sheet's own
/// CTA, and also the write behind the "Deshacer" snackbar action after a
/// chip's deletion (a simple re-insertion, not a restore of the original row).
@injectable
class CreateGoalQuickAmount {
  const CreateGoalQuickAmount(this._repository);

  final GoalQuickAmountsRepository _repository;

  FutureResult<GoalQuickAmount> call({
    required String goalId,
    required int amountMinor,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        const Left(ValidationFailure('quick amount must be greater than 0')),
      );
    }
    return _repository.createQuickAmount(
      goalId: goalId,
      amountMinor: amountMinor,
    );
  }
}
