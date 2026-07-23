import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt_entry.dart';
import '../entities/debt_entry_draft.dart';
import '../repositories/debt_repository.dart';

/// HU-06 (manual mode): "actualizar saldo" — the reconciliation valve. The user
/// types the real figure from the bank and the app records a `manualAdjustment`
/// entry that absorbs the difference against the current derived balance, so
/// the total snaps to the bank exactly with zero math risk.
///
/// The diff is taken against the **raw** outstanding (unclamped) so it is exact
/// even past 0. Returns `Right(null)` when the figure already matches (no entry
/// is written).
@injectable
class UpdateDebtBalance {
  const UpdateDebtBalance(this._repository);

  final DebtRepository _repository;

  FutureResult<DebtEntry?> call({
    required String debtId,
    required int targetOutstandingMinor,
    required DateTime date,
    String? note,
  }) async {
    if (targetOutstandingMinor < 0) {
      return const Left(
        ValidationFailure(
          'the outstanding balance cannot be negative',
          field: 'targetOutstandingMinor',
        ),
      );
    }

    final balanceResult = await _repository.getBalance(debtId);
    return balanceResult.fold<FutureResult<DebtEntry?>>(
      (failure) async => Left(failure),
      (balance) async {
        final diff = targetOutstandingMinor - balance.rawOutstandingMinor;
        if (diff == 0) return const Right(null);

        final entryResult = await _repository.addDebtEntry(
          DebtEntryDraft(
            debtId: debtId,
            kind: DebtEntryKind.manualAdjustment,
            amountMinor: diff,
            entryDate: date,
            note: note,
          ),
        );
        return entryResult.map<DebtEntry?>((entry) => entry);
      },
    );
  }
}
