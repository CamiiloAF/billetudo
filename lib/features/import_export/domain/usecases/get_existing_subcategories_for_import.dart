import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/named_entity.dart';
import '../repositories/import_repository.dart';

/// HU-06 "resolución de destinos": the existing subcategories of an existing
/// root category, for the "mapear a existente" picker.
@injectable
class GetExistingSubcategoriesForImport {
  const GetExistingSubcategoriesForImport(this._repository);

  final ImportRepository _repository;

  FutureResult<List<NamedEntity>> call(String parentId) =>
      _repository.getExistingSubcategories(parentId);
}
