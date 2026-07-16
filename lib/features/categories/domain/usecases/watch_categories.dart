import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/category_node.dart';
import '../repositories/category_repository.dart';

/// HU-05/HU-12: active categories of `kind`, grouped root -> subcategories
/// and ordered by `sortOrder`, to feed the main listing's accordion.
@injectable
class WatchCategories {
  const WatchCategories(this._repository);

  final CategoryRepository _repository;

  Stream<Result<List<CategoryNode>>> call(CategoryKind kind) =>
      _repository.watchCategories(kind);
}
