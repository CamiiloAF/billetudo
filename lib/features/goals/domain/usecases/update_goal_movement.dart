import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_contribution_draft.dart';
import '../repositories/goal_repository.dart';

/// The "Editar movimiento" sheet for a tracking-only movement
/// (`transactionId == null`): rewrites its `amountMinor`/`date`/`note` in
/// place — never deletes and recreates the `GoalContribution` row. A
/// money-moving movement must still be edited through its linked
/// `Transaction` (rejected here, mirrors `GoalRepository.updateContribution`'s
/// own guard so the caller never round-trips to Drift for something that will
/// always fail).
///
/// Reuses `WithdrawFromGoal`'s "never leave `savedMinor` negative" invariant,
/// but excludes this movement's OWN previous amount from the check — editing
/// a retiro back down, for instance, must not be rejected against a
/// `savedMinor` that still counts its old, larger amount.
@injectable
class UpdateGoalMovement {
  const UpdateGoalMovement(this._repository);

  final GoalRepository _repository;

  FutureResult<Unit> call({
    required String contributionId,
    required int amountMinor,
    required DateTime date,
    String? note,
  }) async {
    if (amountMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the amount must be a positive integer of cents',
          field: GoalContributionDraft.fieldAmountMinor,
        ),
      );
    }

    final movementResult = await _repository.getContribution(contributionId);
    if (movementResult case Left(value: final failure)) {
      return Left(failure);
    }
    final movement =
        movementResult.getOrElse((_) => throw StateError('unreachable'));

    if (movement.transactionId != null) {
      return const Left(
        ValidationFailure(
          'a money-moving movement can only be edited through its linked '
          'transaction',
        ),
      );
    }

    final savedResult = await _repository.getSavedMinor(movement.goalId);
    if (savedResult case Left(value: final failure)) {
      return Left(failure);
    }
    final savedMinor = savedResult.getOrElse((_) => 0);

    // Undo this movement's own signed effect before applying its new one, so
    // the invariant is checked against the ledger as it will read AFTER the
    // edit, not as it reads with the stale amount still counted twice.
    final savedExcludingThisMovement = savedMinor - movement.signedMinor;
    final newSignedMinor =
        movement.direction == GoalMovementDirection.contribution
            ? amountMinor
            : -amountMinor;
    if (savedExcludingThisMovement + newSignedMinor < 0) {
      return const Left(
        ValidationFailure(
          'a withdrawal cannot leave the goal\'s saved amount negative',
          field: GoalContributionDraft.fieldAmountMinor,
        ),
      );
    }

    final trimmedNote = note?.trim();

    return _repository.updateContribution(
      contributionId: contributionId,
      amountMinor: amountMinor,
      date: date,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
  }
}
