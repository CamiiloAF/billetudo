import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/named_entity.dart';
import '../repositories/import_repository.dart';

/// HU-06 "resolución de destinos": the existing root categories of the given
/// kind the "mapear a existente" picker offers.
@injectable
class GetExistingRootCategoriesForImport {
  const GetExistingRootCategoriesForImport(this._repository);

  final ImportRepository _repository;

  FutureResult<List<NamedEntity>> call({required bool isExpense}) =>
      _repository.getExistingRootCategories(isExpense: isExpense);
}
