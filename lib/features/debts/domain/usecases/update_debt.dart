import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_draft.dart';
import '../repositories/debt_repository.dart';

/// HU-05: edits a debt. Requires `draft.id`. Editing the opening balance never
/// touches the recorded ledger (abonos and entries stay as they were).
@injectable
class UpdateDebt {
  const UpdateDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Debt> call(DebtDraft draft) {
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
    return draft.validated().fold<FutureResult<Debt>>(
          (failure) async => Left(failure),
          _repository.updateDebt,
        );
  }
}
