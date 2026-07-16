import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-03: reads the full account number from the device's secure storage, to
/// reveal or copy it. Returns `null` when the account has none stored.
///
/// The value is never cached nor persisted anywhere else: each reveal reads it
/// again.
@injectable
class GetAccountNumber {
  const GetAccountNumber(this._repository);

  final AccountRepository _repository;

  FutureResult<String?> call(String id) => _repository.readAccountNumber(id);
}
