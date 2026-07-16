import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/category.dart';
import '../../domain/entities/category_draft.dart';

/// Translates between Drift's generated rows and the domain entities. The
/// only place where `*Data`/`*Companion` types meet the domain, so no
/// generated type ever escapes `data/`.
///
/// Enums are mapped explicitly (not by index) because they are stored as
/// text for parity with Postgres: the domain owns its own enum, and the two
/// are matched by meaning, not by declaration order.
abstract final class CategoryMapper {
  static Category toEntity(db.Category row) => Category(
        id: row.id,
        name: row.name,
        kind: _kindToDomain(row.kind),
        parentId: row.parentId,
        icon: row.icon,
        color: row.color,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Insert companion. `id` is left to Drift's `clientDefault` (UUID).
  static db.CategoriesCompanion toInsertCompanion(
    CategoryDraft draft, {
    required int sortOrder,
    required DateTime now,
  }) =>
      db.CategoriesCompanion.insert(
        name: draft.name,
        kind: kindToDb(draft.kind),
        parentId: Value(draft.parentId),
        icon: Value(draft.icon),
        color: Value(draft.color),
        sortOrder: Value(sortOrder),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

  /// Update companion. `name`/`icon`/`color`/`kind`/`parentId` are written
  /// explicitly (`Value(null)` rather than `absent()`) so clearing icon/color
  /// actually clears them (HU-03) instead of silently keeping the old value.
  static db.CategoriesCompanion toUpdateCompanion(
    CategoryDraft draft, {
    required DateTime now,
  }) =>
      db.CategoriesCompanion(
        name: Value(draft.name),
        kind: Value(kindToDb(draft.kind)),
        parentId: Value(draft.parentId),
        icon: Value(draft.icon),
        color: Value(draft.color),
        updatedAt: Value(now),
      );

  static db.CategoryKind kindToDb(CategoryKind kind) => switch (kind) {
        CategoryKind.income => db.CategoryKind.income,
        CategoryKind.expense => db.CategoryKind.expense,
      };

  static CategoryKind _kindToDomain(db.CategoryKind kind) => switch (kind) {
        db.CategoryKind.income => CategoryKind.income,
        db.CategoryKind.expense => CategoryKind.expense,
      };
}
