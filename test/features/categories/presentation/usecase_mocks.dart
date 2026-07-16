import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/usecases/create_category.dart';
import 'package:billetudo/features/categories/domain/usecases/delete_category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category_deletion_impact.dart';
import 'package:billetudo/features/categories/domain/usecases/reorder_categories.dart';
import 'package:billetudo/features/categories/domain/usecases/update_category.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_parent_candidates.dart';
import 'package:mocktail/mocktail.dart';

/// The cubits only ever talk to use cases, so these are the only seams the
/// presentation tests need — same rule as Accounts' `usecase_mocks.dart`.
class MockWatchCategories extends Mock implements WatchCategories {}

class MockWatchParentCandidates extends Mock implements WatchParentCandidates {}

class MockReorderCategories extends Mock implements ReorderCategories {}

class MockCreateCategory extends Mock implements CreateCategory {}

class MockUpdateCategory extends Mock implements UpdateCategory {}

class MockGetCategory extends Mock implements GetCategory {}

class MockGetCategoryDeletionImpact extends Mock
    implements GetCategoryDeletionImpact {}

class MockDeleteCategory extends Mock implements DeleteCategory {}

/// Fallbacks mocktail needs for `any()` on the feature's own types.
void registerCategoryPresentationFallbacks() {
  registerFallbackValue(
    const CategoryDraft(name: 'fallback', kind: CategoryKind.expense),
  );
  registerFallbackValue(CategoryKind.expense);
  registerFallbackValue(const TransactionResolution.none());
  registerFallbackValue(const SubcategoryResolution.none());
}
