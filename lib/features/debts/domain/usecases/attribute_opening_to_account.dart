import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

/// Item 2 (retro-link): attributes an existing debt's opening balance to an
/// account. Converts the `principalMinor` opening into a linked `disbursement`
/// `Transaction` (see [DebtRepository.attributeOpeningToAccount]) so the same
/// figure now moves the chosen account. The derived balance is unchanged.
@injectable
class AttributeOpeningToAccount {
  const AttributeOpeningToAccount(this._repository);

  final DebtRepository _repository;

  FutureResult<Debt> call({
    required String debtId,
    required String accountId,
  }) {
    if (accountId.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('an account is required', field: 'accountId'),
        ),
      );
    }
    return _repository.attributeOpeningToAccount(
      debtId: debtId,
      accountId: accountId,
    );
  }
}
