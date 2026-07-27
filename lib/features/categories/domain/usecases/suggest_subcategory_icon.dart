import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category_icon_catalog.dart';
import '../repositories/category_repository.dart';

/// HU-02: picks a starting icon for a new subcategory of a given parent that
/// is distinct from every one of its active siblings — instead of copying the
/// parent's icon (which made every subcategory look identical) or a fixed
/// icon (which collided the moment a user created a second subcategory).
///
/// Returns the first name in [CategoryIconCatalog.names] not already used by
/// an active sibling. Falls back to the catalog's first icon if every one of
/// its 64 entries is already taken (an unlikely edge case, but this must
/// never crash or return nothing).
@injectable
class SuggestSubcategoryIcon {
  const SuggestSubcategoryIcon(this._repository);

  final CategoryRepository _repository;

  FutureResult<String> call(String parentId) async {
    final result = await _repository.getActiveSubcategories(parentId);
    return result.map((siblings) {
      final usedIcons = siblings.map((s) => s.icon).whereType<String>().toSet();
      for (final name in CategoryIconCatalog.names) {
        if (!usedIcons.contains(name)) {
          return name;
        }
      }
      return CategoryIconCatalog.names.first;
    });
  }
}
