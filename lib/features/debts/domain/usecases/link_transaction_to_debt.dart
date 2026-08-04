import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

/// HU-02 (Fase 0): attributes an already-registered `Transaction` to a debt by
/// setting its `debtId`. The movement already moved its account; linking only
/// makes it count in the debt's derived balance (as an abono or a disbursement
/// per `direction` × `type`), avoiding a duplicate when the user had recorded
/// the payment as a normal movement.
///
/// budget-income-counts-in-budget (criterion 3): the repository — which
/// already has both rows in hand — decides whether linking must also force
/// `countsInBudget = true` (see `DebtRepository.linkTransactionToDebt`'s
/// doc). No extra orchestration is needed here: this use case's only job
/// stays validating the ids and the debt's closed state, same as before.
@injectable
class LinkTransactionToDebt {
  const LinkTransactionToDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call({
    required String transactionId,
    required String debtId,
  }) async {
    if (transactionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          'a transaction id is required',
          field: 'transactionId',
        ),
      );
    }
    if (debtId.trim().isEmpty) {
      return const Left(
        ValidationFailure('a debt id is required', field: 'debtId'),
      );
    }

    final debtResult = await _repository.getDebt(debtId);
    return debtResult.fold(
      (failure) async => Left(failure),
      (debt) {
        if (debt.isClosed) {
          return Future.value(
            const Left(
              ValidationFailure(
                'a closed debt accepts no new links',
                field: 'closedAt',
              ),
            ),
          );
        }
        return _repository.linkTransactionToDebt(
          transactionId: transactionId,
          debtId: debtId,
        );
      },
    );
  }
}
