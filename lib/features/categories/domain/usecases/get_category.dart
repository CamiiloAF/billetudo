import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Reads a single category by id. Needed by `CategoryFormCubit` to load the
/// category being edited (HU-03) — routing only carries the id, never the
/// full entity.
@injectable
class GetCategory {
  const GetCategory(this._repository);

  final CategoryRepository _repository;

  FutureResult<Category> call(String id) => _repository.getCategory(id);
}
