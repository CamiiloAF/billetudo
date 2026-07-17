import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// HU-01/02: the `limit` most-used categories of a `kind`, feeding the
/// transaction form's Category Quick Picker (the row of quick chips). Usage is
/// measured by the count of active transactions referencing each category;
/// a user with no history falls back to the earliest categories by
/// `sortOrder` (resolved in the repository/datasource).
@injectable
class GetMostUsedCategories {
  const GetMostUsedCategories(this._repository);

  final CategoryRepository _repository;

  FutureResult<List<Category>> call(CategoryKind kind, {int limit = 3}) =>
      _repository.getMostUsedCategories(kind, limit: limit);
}
