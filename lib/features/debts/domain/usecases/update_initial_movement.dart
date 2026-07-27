import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_cash_event.dart';
import '../repositories/debt_repository.dart';
import '../services/debt_event_rules.dart';

/// Item 2b: syncs a debt's linked opening movement after the opening figure was
/// edited. The concrete `income`/`expense` type is derived from the (possibly
/// new) `direction` — a disbursement stays a disbursement, so an edit that
/// flipped the debt's direction flips the movement's type too, keeping the
/// derived balance an increase.
///
/// When `date` is provided the movement's date is re-synced to it as well: the
/// registro inicial IS the debt's opening event, so its date must always equal
/// the debt's `startDate`. Moving that date changes no account balance, so it
/// is applied silently — analogous to the silent `type` re-sync on a direction
/// change.
@injectable
class UpdateInitialMovement {
  const UpdateInitialMovement(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call({
    required String transactionId,
    required int amountMinor,
    required DebtDirection direction,
    DateTime? date,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the opening amount must be a positive integer of cents',
            field: 'amountMinor',
          ),
        ),
      );
    }
    return _repository.updateInitialMovementAmount(
      transactionId: transactionId,
      amountMinor: amountMinor,
      type: DebtEventRules.cashEventType(
        direction: direction,
        kind: DebtCashEventKind.disbursement,
      ),
      date: date,
    );
  }
}
