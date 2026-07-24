import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

/// Extension (HU-07): manually closes a debt — a pure status change
/// (`closedAt`), never a `DebtEntry`. Used both by the overflow menu's
/// "Cerrar deuda" (a balance may still be pending, frozen thereafter) and by
/// the felicitación sheet's "Completar" (the balance already reached 0).
///
/// A debt cannot be closed twice: closing again would silently overwrite the
/// original `closedAt`, breaking the "Cerrada · <fecha>" the closed list
/// shows.
@injectable
class CloseDebt {
  const CloseDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call(String debtId) async {
    final debtResult = await _repository.getDebt(debtId);
    return debtResult.fold(
      (failure) async => Left(failure),
      (debt) async {
        if (debt.isClosed) {
          return const Left(
            ValidationFailure(
              'the debt is already closed',
              field: 'closedAt',
            ),
          );
        }
        return _repository.closeDebt(debtId);
      },
    );
  }
}
