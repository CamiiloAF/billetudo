import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/named_entity.dart';
import '../repositories/import_repository.dart';

/// HU-06 "resolución de destinos": the existing accounts the "mapear a
/// existente" picker offers for a CSV account name with no automatic match.
@injectable
class GetExistingAccountsForImport {
  const GetExistingAccountsForImport(this._repository);

  final ImportRepository _repository;

  FutureResult<List<NamedEntity>> call() => _repository.getExistingAccounts();
}
