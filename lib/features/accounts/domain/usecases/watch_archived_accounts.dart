import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account_with_balance.dart';
import '../repositories/account_repository.dart';

/// HU-07: the archived accounts list, where the user can bring one back.
@injectable
class WatchArchivedAccounts {
  const WatchArchivedAccounts(this._repository);

  final AccountRepository _repository;

  Stream<Result<List<AccountWithBalance>>> call() =>
      _repository.watchArchivedAccounts();
}
