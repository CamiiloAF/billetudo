import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt_cash_event_draft.dart';
import '../repositories/debt_repository.dart';
import '../services/debt_event_rules.dart';

/// HU-02 (toggle "Sí"): registers a cash disbursement or abono as a
/// `Transaction` that carries the debt id and moves an account.
///
/// The concrete `income`/`expense` type is NOT the user's to pick — it follows
/// from the debt's `direction` × the `DebtCashEventKind` (see
/// [DebtEventRules.cashEventType]). The currency is the debt's, so a cash event
/// can never disagree with its debt.
@injectable
class RegisterDebtCashEvent {
  const RegisterDebtCashEvent(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call(DebtCashEventDraft draft) async {
    if (draft.amountMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the amount must be a positive integer of cents',
          field: 'amountMinor',
        ),
      );
    }
    if (draft.accountId.trim().isEmpty) {
      return const Left(
        ValidationFailure('an account is required', field: 'accountId'),
      );
    }

    final debtResult = await _repository.getDebt(draft.debtId);
    return debtResult.fold(
      (failure) async => Left(failure),
      (debt) => _repository.registerCashEvent(
        debtId: debt.id,
        accountId: draft.accountId,
        amountMinor: draft.amountMinor,
        type: DebtEventRules.cashEventType(
          direction: debt.direction,
          kind: draft.kind,
        ),
        currency: debt.currency,
        date: draft.date,
        note: draft.note,
        categoryId: draft.categoryId,
      ),
    );
  }
}
