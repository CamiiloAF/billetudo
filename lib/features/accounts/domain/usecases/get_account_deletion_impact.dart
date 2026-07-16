import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account_deletion_impact.dart';
import '../repositories/account_repository.dart';

/// HU-08: what would be affected by deleting the account, to show before
/// confirming.
@injectable
class GetAccountDeletionImpact {
  const GetAccountDeletionImpact(this._repository);

  final AccountRepository _repository;

  FutureResult<AccountDeletionImpact> call(String id) =>
      _repository.getDeletionImpact(id);
}
