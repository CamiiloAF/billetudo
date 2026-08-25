import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

/// Fix B: deletes a single solo-deuda `DebtEntry` — a cash-less abono,
/// desembolso, an interest accrual, or a manual adjustment. Unlike editing,
/// every kind is deletable, including an `interestAccrual`: it can still be
/// removed to correct an over-eager accrual, just never hand-edited (see
/// `UpdateDebtEntry`).
///
/// The delete is the reversible papelera (`deletedAt`), never `tombstonedAt` —
/// no other table references a `DebtEntry`'s id by foreign key.
@injectable
class DeleteDebtEntry {
  const DeleteDebtEntry(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteDebtEntry(id);
}
