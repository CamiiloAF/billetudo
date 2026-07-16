import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-07: brings an archived account back to the active list.
@injectable
class UnarchiveAccount {
  const UnarchiveAccount(this._repository);

  final AccountRepository _repository;

  FutureResult<Unit> call(String id) =>
      _repository.setArchived(id, archived: false);
}
