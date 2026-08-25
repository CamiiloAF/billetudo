import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt_entry.dart';
import '../repositories/debt_repository.dart';

/// Fix B: edits an existing solo-deuda [DebtEntry] — a cash-less abono,
/// desembolso, or a manual adjustment (`actualizar saldo`). Amount, date and
/// note may change; the entry's `kind` never does (that would be a different
/// event, not an edit).
///
/// An `interestAccrual` is **never editable**: it is generated automatically,
/// not captured by the user, so letting it be hand-edited would break the
/// trace of how the current balance was reached. This use case is the single
/// place that rule is enforced — the sheet only decides whether to *show* the
/// edit action, this is what actually blocks it.
///
/// `magnitudeMinor` is a positive amount; the stored, signed
/// `DebtEntry.amountMinor` is re-derived from it, preserving the entry's own
/// sign rather than recomputing one from its `kind` — a `payment` always
/// stays negative and a `disbursement` always stays positive (their sign is
/// fixed by `DebtEventRules`), while a `manualAdjustment` (which can be signed
/// either way) keeps whichever sign it already had, since an edit corrects a
/// figure, it does not flip its meaning.
@injectable
class UpdateDebtEntry {
  const UpdateDebtEntry(this._repository);

  final DebtRepository _repository;

  FutureResult<DebtEntry> call({
    required String id,
    required int magnitudeMinor,
    required DateTime entryDate,
    String? note,
  }) async {
    if (magnitudeMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the amount must be a positive integer of cents',
          field: 'amountMinor',
        ),
      );
    }

    final entryResult = await _repository.getDebtEntry(id);
    return entryResult.fold(
      (failure) async => Left(failure),
      (entry) {
        if (entry.kind == DebtEntryKind.interestAccrual) {
          return Future.value(
            const Left(
              ValidationFailure(
                'an interest accrual cannot be edited',
                field: 'kind',
              ),
            ),
          );
        }
        final magnitude = magnitudeMinor.abs();
        final amountMinor = switch (entry.kind) {
          DebtEntryKind.disbursement => magnitude,
          DebtEntryKind.payment => -magnitude,
          DebtEntryKind.manualAdjustment =>
            entry.amountMinor < 0 ? -magnitude : magnitude,
          // Unreachable: rejected above.
          DebtEntryKind.interestAccrual => magnitude,
        };
        return _repository.updateDebtEntry(
          id: id,
          amountMinor: amountMinor,
          entryDate: entryDate,
          note: note,
        );
      },
    );
  }
}
