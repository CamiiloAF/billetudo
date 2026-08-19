import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../../scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import '../repositories/goal_repository.dart';

/// HU-16 "Enlazar existente" (Metas → Aporte recurrente): attributes an
/// already-created scheduled payment template to a goal, instead of
/// duplicating it — mirrors `LinkTransactionToGoal`'s "enlazar movimiento
/// existente" pattern for the transaction case.
@injectable
class LinkScheduledPaymentToGoal {
  const LinkScheduledPaymentToGoal(
    this._goalRepository,
    this._scheduledPaymentRepository,
  );

  final GoalRepository _goalRepository;
  final ScheduledPaymentRepository _scheduledPaymentRepository;

  FutureResult<ScheduledPayment> call({
    required String goalId,
    required String scheduledPaymentId,
  }) async {
    final goalResult = await _goalRepository.getGoal(goalId);
    if (goalResult case Left(value: final failure)) {
      return Left(failure);
    }
    final goal = goalResult.getOrElse((_) => throw StateError('unreachable'));
    if (goal.isArchived) {
      return const Left(
        ValidationFailure(
          'an archived goal cannot receive a new recurring contribution',
        ),
      );
    }

    final templateResult =
        await _scheduledPaymentRepository.getScheduledPayment(
      scheduledPaymentId,
    );
    if (templateResult case Left(value: final failure)) {
      return Left(failure);
    }
    final template =
        templateResult.getOrElse((_) => throw StateError('unreachable'));
    if (template.debtId != null || template.goalId != null) {
      return const Left(
        ValidationFailure(
          'this scheduled payment is already linked to a debt or a goal',
        ),
      );
    }

    return _scheduledPaymentRepository.linkScheduledPaymentToGoal(
      scheduledPaymentId: scheduledPaymentId,
      goalId: goalId,
    );
  }
}
