import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/category_repository.dart';

/// HU-04: undo from the trash. Clears `deletedAt` without touching
/// `tombstonedAt` (this feature never writes it) and without requiring the
/// category's parent to still be alive — a category restored under a parent
/// that was itself deleted comes back as a visible orphan, a known,
/// non-blocking edge case for this scope (see `categorias.md`).
@injectable
class RestoreCategory {
  const RestoreCategory(this._repository);

  final CategoryRepository _repository;

  FutureResult<Unit> call(String id) => _repository.restoreCategory(id);
}
