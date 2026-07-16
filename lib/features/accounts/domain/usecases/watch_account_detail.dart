import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account_with_balance.dart';
import '../repositories/account_repository.dart';

/// HU-04: one account with its balance/credit figures, live.
@injectable
class WatchAccountDetail {
  const WatchAccountDetail(this._repository);

  final AccountRepository _repository;

  Stream<Result<AccountWithBalance>> call(String id) =>
      _repository.watchAccount(id);
}
