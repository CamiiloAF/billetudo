import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account_with_balance.dart';
import '../repositories/account_repository.dart';

/// HU-04/HU-09: active accounts with their live balance, ordered by
/// `sortOrder`.
@injectable
class WatchAccounts {
  const WatchAccounts(this._repository);

  final AccountRepository _repository;

  Stream<Result<List<AccountWithBalance>>> call() =>
      _repository.watchActiveAccounts();
}
