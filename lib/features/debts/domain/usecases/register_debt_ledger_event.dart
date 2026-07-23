import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt_cash_event.dart';
import '../entities/debt_entry.dart';
import '../entities/debt_entry_draft.dart';
import '../repositories/debt_repository.dart';
import '../services/debt_event_rules.dart';

/// HU-02 (toggle "No"): registers a cash-less disbursement or abono. It changes
/// the debt (up for a disbursement, down for an abono) but moves no account and
/// touches no budget — "lo pagó otro / fue en efectivo / por fuera".
///
/// Persists a solo-deuda `DebtEntry` of kind `payment`/`disbursement`, with the
/// sign resolved by [DebtEventRules.ledgerEventAmount] from a positive
/// magnitude the caller supplies.
@injectable
class RegisterDebtLedgerEvent {
  const RegisterDebtLedgerEvent(this._repository);

  final DebtRepository _repository;

  FutureResult<DebtEntry> call({
    required String debtId,
    required DebtCashEventKind kind,
    required int amountMinor,
    required DateTime date,
    String? note,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the amount must be a positive integer of cents',
            field: 'amountMinor',
          ),
        ),
      );
    }

    return _repository.addDebtEntry(
      DebtEntryDraft(
        debtId: debtId,
        kind: kind == DebtCashEventKind.disbursement
            ? DebtEntryKind.disbursement
            : DebtEntryKind.payment,
        amountMinor: DebtEventRules.ledgerEventAmount(
          kind: kind,
          magnitudeMinor: amountMinor,
        ),
        entryDate: date,
        note: note,
      ),
    );
  }
}
