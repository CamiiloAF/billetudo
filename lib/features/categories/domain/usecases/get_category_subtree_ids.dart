import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/category_repository.dart';

/// Expands a category id into "itself + every active subcategory under it",
/// mirroring the symmetric root/subcategory selection rule
/// `TransactionFilter.toggleRootCategory` already applies in the category
/// filter sheet (HU-06). Movements are always tagged with the exact category
/// the user picked at capture time — a root's own transactions use the root
/// id, but transactions logged under one of its subcategories use that
/// subcategory's id, never the root's. Any consumer that means "this
/// category and everything under it" (e.g. Gráficas' categories drill-down
/// into Movimientos) needs this expansion; a plain `{categoryId}` filter
/// would silently miss every subcategory-tagged movement.
///
/// A `categoryId` that is itself a subcategory (has a `parentId`) has
/// nothing to expand: it returns just `{categoryId}`, since a subcategory's
/// movements are always tagged with its own id.
@injectable
class GetCategorySubtreeIds {
  const GetCategorySubtreeIds(this._repository);

  final CategoryRepository _repository;

  FutureResult<Set<String>> call(String categoryId) async {
    final categoryResult = await _repository.getCategory(categoryId);
    switch (categoryResult) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final category):
        if (category.parentId != null) {
          return Right({categoryId});
        }
        final subcategoriesResult =
            await _repository.getActiveSubcategories(categoryId);
        switch (subcategoriesResult) {
          case Left(value: final failure):
            return Left(failure);
          case Right(value: final subcategories):
            return Right({
              categoryId,
              for (final subcategory in subcategories) subcategory.id,
            });
        }
    }
  }
}
