import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-07: hides the account from active flows without touching its history.
@injectable
class ArchiveAccount {
  const ArchiveAccount(this._repository);

  final AccountRepository _repository;

  FutureResult<Unit> call(String id) =>
      _repository.setArchived(id, archived: true);
}
