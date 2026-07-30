import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/named_entity.dart';
import '../repositories/import_repository.dart';

/// HU-06 "resolución de destinos": the existing tags the "mapear a
/// existente" picker offers.
@injectable
class GetExistingTagsForImport {
  const GetExistingTagsForImport(this._repository);

  final ImportRepository _repository;

  FutureResult<List<NamedEntity>> call() => _repository.getExistingTags();
}
