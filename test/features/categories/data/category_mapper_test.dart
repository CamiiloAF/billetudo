import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/categories/data/models/category_mapper.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    as domain;
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 15);

  test('toEntity mapea kind por significado, no por índice', () {
    final row = db.Category(
      id: 'cat-1',
      name: 'Comida',
      kind: db.CategoryKind.expense,
      icon: 'utensils',
      color: 'mint',
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    final entity = CategoryMapper.toEntity(row);

    expect(entity.kind, domain.CategoryKind.expense);
    expect(entity.icon, 'utensils');
    expect(entity.color, 'mint');
    expect(entity.isRoot, isTrue);
  });

  test(
      'toInsertCompanion asigna el sortOrder dado y stampa createdAt/'
      'updatedAt', () {
    const draft = CategoryDraft(
      name: 'Comida',
      kind: domain.CategoryKind.expense,
      parentId: 'root-1',
    );

    final companion =
        CategoryMapper.toInsertCompanion(draft, sortOrder: 3, now: now);

    expect(companion.name.value, 'Comida');
    expect(companion.kind.value, db.CategoryKind.expense);
    expect(companion.parentId, const Value('root-1'));
    expect(companion.sortOrder.value, 3);
    expect(companion.createdAt.value, now);
    expect(companion.updatedAt.value, now);
  });

  test('toUpdateCompanion escribe icon/color explícitos, incluso null', () {
    const draft = CategoryDraft(
      id: 'cat-1',
      name: 'Comida',
      kind: domain.CategoryKind.expense,
    );

    final companion = CategoryMapper.toUpdateCompanion(draft, now: now);

    expect(companion.icon, const Value(null));
    expect(companion.color, const Value(null));
    expect(companion.updatedAt.value, now);
  });
}
