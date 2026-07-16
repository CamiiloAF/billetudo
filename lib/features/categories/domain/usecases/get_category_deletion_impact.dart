import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category_deletion_impact.dart';
import '../repositories/category_repository.dart';

/// HU-04: what deleting a category would affect, so the UI can decide which
/// of the 3 confirmation bottom sheets to show (none of the 3 flows starts
/// without this).
@injectable
class GetCategoryDeletionImpact {
  const GetCategoryDeletionImpact(this._repository);

  final CategoryRepository _repository;

  FutureResult<CategoryDeletionImpact> call(String id) =>
      _repository.getDeletionImpact(id);
}
