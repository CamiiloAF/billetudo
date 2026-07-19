import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../models/category_seed_entry.dart';

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

  /// The [limit] most-used categories of [kind] by active-transaction count,
  /// for the transaction form's Category Quick Picker (HU-01/02). Counts
  /// transactions still alive (`deletedAt`/`tombstonedAt` null) that reference
  /// each alive category. Ties — and the whole result for a user with no
  /// history, where every count is zero — fall back to the earliest root
  /// categories first, then by `sortOrder`, so a fresh user still gets a
  /// sensible default set.
  Future<List<Category>> mostUsedCategories(CategoryKind kind, int limit) {
    final usageCount = _db.transactions.id.count();
    final query = _db.select(_db.categories).join([
      leftOuterJoin(
        _db.transactions,
        _db.transactions.categoryId.equalsExp(_db.categories.id) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.tombstonedAt.isNull(),
      ),
    ])
      ..where(_db.categories.kind.equalsValue(kind) & _alive)
      ..groupBy([_db.categories.id])
      ..orderBy([
        OrderingTerm.desc(usageCount),
        // Roots (parentId IS NULL -> 1) before subcategories on a tie, so the
        // no-history fallback favours top-level categories.
        OrderingTerm.desc(_db.categories.parentId.isNull()),
        OrderingTerm.asc(_db.categories.sortOrder),
        OrderingTerm.asc(_db.categories.createdAt),
      ])
      ..limit(limit);
    return query.map((row) => row.readTable(_db.categories)).get();
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
            CategoriesCompanion(
                sortOrder: Value(index),
                updatedAt: Value(now.millisecondsSinceEpoch)),
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

  /// Active (not deleted, not tombstoned, not closed) budgets whose scope
  /// references [categoryId] (Presupuestos delete-impact rule). Counts the raw
  /// join row; the budget is never cascaded, and a deleted category stays in
  /// scope for later restore.
  Future<int> countReferencingBudgets(String categoryId) {
    final count = _db.budgetCategories.id.count();
    final query = _db.selectOnly(_db.budgetCategories).join([
      innerJoin(
        _db.budgets,
        _db.budgets.id.equalsExp(_db.budgetCategories.budgetId),
      ),
    ])
      ..addColumns([count])
      ..where(
        _db.budgetCategories.categoryId.equals(categoryId) &
            _db.budgetCategories.deletedAt.isNull() &
            _db.budgetCategories.tombstonedAt.isNull() &
            _db.budgets.deletedAt.isNull() &
            _db.budgets.tombstonedAt.isNull() &
            _db.budgets.archivedAt.isNull(),
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
        CategoriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch)),
      );

  /// HU-04 case 3 (cascade): soft-deletes [rootId] and every active
  /// subcategory of it, in one transaction.
  Future<void> cascadeDeleteCategory(String rootId, DateTime now) =>
      _db.transaction(() async {
        await (_db.update(_db.categories)
              ..where((c) => c.parentId.equals(rootId) & _alive))
            .write(
          CategoriesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch)),
        );
        await (_db.update(_db.categories)
              ..where((c) => c.id.equals(rootId) & _alive))
            .write(
          CategoriesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch)),
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
            parentId: Value(targetRootId),
            updatedAt: Value(now.millisecondsSinceEpoch)),
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
          updatedAt: Value(now.millisecondsSinceEpoch),
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
          updatedAt: Value(now.millisecondsSinceEpoch),
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
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          )
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-06: inserts the onboarding seed set fetched from the remote
  /// `category_seeds` catalog (`docs/requirements/05-auth-sync.md`, decision
  /// #12), in one transaction.
  ///
  /// Unlike a normal [insertCategory], every row keeps the catalog's own
  /// stable [CategorySeedEntry.id] instead of Drift's random `clientDefault`
  /// UUID — the whole point of the decision: it lets HU-04's merge detect,
  /// by primary key, whether the signed-in account already seeded this exact
  /// category before.
  ///
  /// Roots are inserted before subcategories regardless of the catalog's own
  /// row order, since `Categories.parentId` is a real FK and a subcategory
  /// would otherwise fail to insert before its root exists. [languageCode]
  /// picks which of the catalog's `name_es`/`name_en` becomes the local
  /// `Categories.name` (see `AppLocale.resolveLanguageCode`); once seeded the
  /// name is just a normal, editable field like any other category's.
  Future<void> seedDefaultCategories(
    List<CategorySeedEntry> catalog,
    DateTime now,
    String languageCode,
  ) =>
      _db.transaction(() async {
        final roots = catalog.where((entry) => entry.isRoot);
        final subcategories = catalog.where((entry) => !entry.isRoot);
        for (final entry in [...roots, ...subcategories]) {
          await insertCategory(
            CategoriesCompanion.insert(
              id: Value(entry.id),
              name: entry.nameFor(languageCode),
              kind: entry.kind,
              parentId: Value(entry.parentId),
              icon: Value(entry.icon),
              color: Value(entry.color),
              sortOrder: Value(entry.sortOrder),
              createdAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
        }
      });
}
