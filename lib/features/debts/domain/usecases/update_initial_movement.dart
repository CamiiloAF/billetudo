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
@injectable
class UpdateInitialMovement {
  const UpdateInitialMovement(this._repository);

  final DebtRepository _repository;

  FutureResult<Unit> call({
    required String transactionId,
    required int amountMinor,
    required DebtDirection direction,
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
    );
  }
}
