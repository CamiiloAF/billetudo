import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import 'default_categories_seed.dart';

/// Drift queries for the Categories feature.
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`: no new tables, no forced schema regeneration.
///
/// Unlike Accounts, this feature never writes `tombstonedAt` — every delete
/// flow resolves dependent transactions/subcategories before soft-deleting
/// the category via `deletedAt`, so a referential-integrity tombstone is
/// never needed. Every read below still guards `tombstonedAt IS NULL` for
/// defense in depth (the column always being null for rows this feature
/// wrote), and `deletedAt IS NULL` to exclude the trash.
@lazySingleton
class CategoriesLocalDatasource {
  const CategoriesLocalDatasource(this._db);

  final AppDatabase _db;

  Expression<bool> get _alive =>
      _db.categories.deletedAt.isNull() & _db.categories.tombstonedAt.isNull();

  Stream<List<Category>> watchCategories(CategoryKind kind) {
    final query = _db.select(_db.categories)
      ..where((c) => c.kind.equalsValue(kind) & _alive)
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.createdAt),
      ]);
    return query.watch();
  }

  Stream<List<Category>> watchParentCandidates(
    CategoryKind kind, {
    String? excludingId,
  }) {
    final query = _db.select(_db.categories)
      ..where(
        (c) =>
            c.kind.equalsValue(kind) &
            c.parentId.isNull() &
            _alive &
            (excludingId == null
                ? const Constant(true)
                : c.id.equals(excludingId).not()),
      )
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch();
  }

  Future<Category?> getCategory(String id) =>
      (_db.select(_db.categories)..where((c) => c.id.equals(id) & _alive))
          .getSingleOrNull();

  Future<Category> insertCategory(CategoriesCompanion companion) =>
      _db.into(_db.categories).insertReturning(companion);

  /// Every normal edit funnels through here, so the "alive" guard lives here
  /// too: a trashed category must not be silently mutated. No match returns
  /// `null`, which the repository turns into a `NotFoundFailure`.
  Future<Category?> updateCategory(
    String id,
    CategoriesCompanion companion,
  ) =>
      (_db.update(_db.categories)..where((c) => c.id.equals(id) & _alive))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-05: rewrites `sortOrder` as a contiguous 0..n-1 sequence, in one
  /// transaction so the list never reads a half-applied order.
  Future<void> reorderCategories(List<String> orderedIds, DateTime now) =>
      _db.transaction(() async {
        for (var index = 0; index < orderedIds.length; index++) {
          await (_db.update(_db.categories)
                ..where((c) => c.id.equals(orderedIds[index]) & _alive))
              .write(
            CategoriesCompanion(sortOrder: Value(index), updatedAt: Value(now)),
          );
        }
      });

  /// Next `sortOrder` within [kind]: among root categories when [parentId] is
  /// `null`, or among the siblings of [parentId] otherwise.
  Future<int> nextSortOrder(CategoryKind kind, {String? parentId}) async {
    final maxOrder = _db.categories.sortOrder.max();
    final query = _db.selectOnly(_db.categories)
      ..addColumns([maxOrder])
      ..where(
        _db.categories.kind.equalsValue(kind) &
            (parentId == null
                ? _db.categories.parentId.isNull()
                : _db.categories.parentId.equals(parentId)) &
            _alive,
      );
    final row = await query.getSingleOrNull();
    final current = row?.read(maxOrder);
    return current == null ? 0 : current + 1;
  }

  Future<int> countActiveSubcategories(String parentId) {
    final count = _db.categories.id.count();
    final query = _db.selectOnly(_db.categories)
      ..addColumns([count])
      ..where(_db.categories.parentId.equals(parentId) & _alive);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> countActiveTransactions(String categoryId) {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(
        _db.transactions.categoryId.equals(categoryId) &
            _db.transactions.deletedAt.isNull(),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> countActiveCategories() {
    final count = _db.categories.id.count();
    final query = _db.selectOnly(_db.categories)
      ..addColumns([count])
      ..where(_alive);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// HU-04 case 1/2: plain soft delete.
  Future<Category?> softDeleteCategory(String id, DateTime now) =>
      updateCategory(
        id,
        CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

  /// HU-04 case 3 (cascade): soft-deletes [rootId] and every active
  /// subcategory of it, in one transaction.
  Future<void> cascadeDeleteCategory(String rootId, DateTime now) =>
      _db.transaction(() async {
        await (_db.update(_db.categories)
              ..where((c) => c.parentId.equals(rootId) & _alive))
            .write(
          CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
        await (_db.update(_db.categories)
              ..where((c) => c.id.equals(rootId) & _alive))
            .write(
          CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
      });

  /// HU-04 case 3 (reassign): moves every active subcategory of [rootId]
  /// under [targetRootId].
  Future<void> reassignSubcategories(
    String rootId,
    String targetRootId,
    DateTime now,
  ) =>
      (_db.update(_db.categories)
            ..where((c) => c.parentId.equals(rootId) & _alive))
          .write(
        CategoriesCompanion(
            parentId: Value(targetRootId), updatedAt: Value(now)),
      );

  /// HU-04 case 2 (reassign): moves every active transaction referencing
  /// [fromCategoryId] to [toCategoryId].
  Future<void> reassignTransactions(
    String fromCategoryId,
    String toCategoryId,
    DateTime now,
  ) =>
      (_db.update(_db.transactions)
            ..where(
              (t) => t.categoryId.equals(fromCategoryId) & t.deletedAt.isNull(),
            ))
          .write(
        TransactionsCompanion(
          categoryId: Value(toCategoryId),
          updatedAt: Value(now),
        ),
      );

  /// HU-04 case 2 (leave uncategorized): clears `categoryId` on every active
  /// transaction referencing [categoryId].
  Future<void> clearTransactionCategory(String categoryId, DateTime now) =>
      (_db.update(_db.transactions)
            ..where(
              (t) => t.categoryId.equals(categoryId) & t.deletedAt.isNull(),
            ))
          .write(
        TransactionsCompanion(
          categoryId: const Value(null),
          updatedAt: Value(now),
        ),
      );

  /// Undo from the trash. Only guards `tombstonedAt IS NULL`, on purpose: the
  /// row being restored is, by definition, currently `deletedAt IS NOT NULL`.
  Future<Category?> restoreCategory(String id, DateTime now) =>
      (_db.update(_db.categories)
            ..where(
              (c) => c.id.equals(id) & c.tombstonedAt.isNull(),
            ))
          .writeReturning(
            CategoriesCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
          )
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-06: inserts the whole onboarding seed set in one transaction. Each
  /// root/subcategory gets a contiguous `sortOrder` within its own scope,
  /// following the appendix order.
  Future<void> seedDefaultCategories(DateTime now) => _db.transaction(
        () async {
          for (final entry in defaultCategorySeed.entries) {
            final kind = entry.key;
            var rootOrder = 0;
            for (final root in entry.value) {
              final rootRow = await insertCategory(
                CategoriesCompanion.insert(
                  name: root.name,
                  kind: kind,
                  icon: Value(root.icon),
                  color: Value(root.color),
                  sortOrder: Value(rootOrder),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
              rootOrder++;

              var subOrder = 0;
              for (final sub in root.subcategories) {
                await insertCategory(
                  CategoriesCompanion.insert(
                    name: sub.name,
                    kind: kind,
                    parentId: Value(rootRow.id),
                    icon: Value(sub.icon),
                    color: Value(sub.color),
                    sortOrder: Value(subOrder),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                  ),
                );
                subOrder++;
              }
            }
          }
        },
      );
}
