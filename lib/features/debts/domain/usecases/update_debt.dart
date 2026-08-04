import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_draft.dart';
import '../repositories/debt_repository.dart';

/// HU-05: edits a debt. Requires `draft.id`. Editing the opening balance never
/// touches the recorded ledger (abonos and entries stay as they were).
///
/// Fix 9 (scenario 2): a debt's `direction` drives how `DebtEventRules`
/// interprets the sign of every cash event **live**, at balance-calculation
/// time — it is never stored per-event. So changing `direction` once the debt
/// already has movements beyond its opening would silently flip the meaning
/// of that whole history (an abono could turn into a disbursement) instead of
/// updating anything about those movements themselves. The opening movement
/// itself is the one exception — its `type` is re-synced to the new direction
/// by `UpdateInitialMovement`, which preserves its meaning rather than
/// flipping it — so this only blocks when there is more than just the
/// opening. `directionChanged`/`hasNonOpeningMovements` are the caller's
/// (`DebtFormCubit`) precomputed facts: this use case has no ledger to derive
/// them from on its own.
@injectable
class UpdateDebt {
  const UpdateDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Debt> call(
    DebtDraft draft, {
    bool directionChanged = false,
    bool hasNonOpeningMovements = false,
  }) {
    if (draft.id == null) {
      return Future.value(
        const Left(
          ValidationFailure(
            'cannot update a debt without an id',
            field: DebtDraft.fieldId,
          ),
        ),
      );
    }
    if (directionChanged && hasNonOpeningMovements) {
      return Future.value(
        const Left(
          ValidationFailure(
            'cannot change direction: this debt already has movements '
            'beyond its opening, changing direction would silently '
            'reinterpret their historical sign',
            field: DebtDraft.fieldDirection,
          ),
        ),
      );
    }
    return draft.validated().fold<FutureResult<Debt>>(
          (failure) async => Left(failure),
          _repository.updateDebt,
        );
  }
}
