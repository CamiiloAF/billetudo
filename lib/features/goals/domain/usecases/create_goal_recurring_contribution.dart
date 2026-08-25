import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import '../../../scheduled_payments/domain/usecases/create_scheduled_payment.dart';
import '../repositories/goal_repository.dart';

/// HU-16 "Crear nuevo" (Metas → Aporte recurrente): creates a brand-new
/// scheduled payment template that is this goal's recurring contribution —
/// same shape as a debt's cuota (`docs/requirements/fase-1/08-deudas.md`'s
/// "Configurar cuota"), just linked via [ScheduledPayment.goalId] instead of
/// `debtId`.
///
/// A recurring contribution always moves money OUT of an account into
/// savings, so [ScheduledPaymentType.expense] is fixed here — mirrors how a
/// cuota's direction is fixed by the debt it belongs to, rather than left for
/// the caller to pick.
@injectable
class CreateGoalRecurringContribution {
  const CreateGoalRecurringContribution(
    this._goalRepository,
    this._createScheduledPayment,
  );

  final GoalRepository _goalRepository;
  final CreateScheduledPayment _createScheduledPayment;

  FutureResult<ScheduledPayment> call({
    required String goalId,
    required String accountId,
    required int amountMinor,
    required String currency,
    required ScheduledPaymentFrequency frequency,
    required DateTime nextDate,
    int interval = 1,
    String? categoryId,
    CategoryKind? categoryKind,
    DateTime? endDate,
    bool requiresConfirmation = false,
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

    return _createScheduledPayment(
      ScheduledPaymentDraft(
        accountId: accountId,
        amountMinor: amountMinor,
        currency: currency,
        type: ScheduledPaymentType.expense,
        frequency: frequency,
        nextDate: nextDate,
        interval: interval,
        categoryId: categoryId,
        categoryKind: categoryKind,
        endDate: endDate,
        requiresConfirmation: requiresConfirmation,
        goalId: goalId,
      ),
    );
  }
}
