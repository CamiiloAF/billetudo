import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

/// HU-04: which figure a card highlights (debt or available credit). A per
/// account preference with no effect on the balance calculation.
@injectable
class SetCardBalancePrimary {
  const SetCardBalancePrimary(this._repository);

  final AccountRepository _repository;

  FutureResult<Unit> call(String id, CardBalanceView view) =>
      _repository.setCardBalancePrimary(id, view);
}
