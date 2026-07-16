import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/repositories/category_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerCategoryFallbacks() {
  registerFallbackValue(
    const CategoryDraft(name: 'fallback', kind: CategoryKind.expense),
  );
}

/// Convenience builder for a valid [Category], overridable field by field.
Category buildCategory({
  String id = 'cat-1',
  String name = 'Comida',
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  String? icon,
  String? color,
  int sortOrder = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 7, 15);
  return Category(
    id: id,
    name: name,
    kind: kind,
    parentId: parentId,
    icon: icon,
    color: color,
    sortOrder: sortOrder,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}
