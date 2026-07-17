import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// One scope reference (account or category) of a budget, with whether its
/// referent still exists. Data-layer type: never leaves `data/`.
class BudgetScopeRefRow {
  const BudgetScopeRefRow({
    required this.budgetId,
    required this.refId,
    required this.referentAlive,
  });

  final String budgetId;
  final String refId;
  final bool referentAlive;
}

/// An expense eligible for budget math, enriched with the names the detail
/// activity row shows. Data-layer type.
class BudgetExpenseRow {
  const BudgetExpenseRow({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.date,
    required this.accountName,
    this.categoryId,
    this.categoryName,
    this.note,
  });

  final String id;
  final String accountId;
  final String? categoryId;
  final int amountMinor;
  final String currency;
  final DateTime date;
  final String accountName;
  final String? categoryName;
  final String? note;
}

/// Drift queries for the Budgets feature.
///
/// A plain injected class (not a `@DriftAccessor`): the schema already has every
/// table it needs, so it forces no regeneration. It returns **raw rows**; the
/// scope-matching and progress math live in the domain, which must have a single
/// implementation.
///
/// Two deletion columns are in play and are NOT interchangeable:
///  - A budget's own `archivedAt` (history) / `deletedAt` (trash). The active
///    list filters both out; the archived list wants `archivedAt IS NOT NULL`.
///  - Scope join rows carry their own `deletedAt`/`tombstonedAt` for when the
///    user removes a referent by editing the scope (HU-09) — separate from the
///    referent being deleted in its own feature, which the `referentAlive` flag
///    below reports without touching the join row.
@lazySingleton
class BudgetsLocalDatasource {
  const BudgetsLocalDatasource(this._db);

  final AppDatabase _db;

  // -- Budgets ---------------------------------------------------------------

  /// Active budgets: neither closed nor trashed, newest first.
  Stream<List<Budget>> watchActiveBudgets() => (_db.select(_db.budgets)
        ..where((b) => b.archivedAt.isNull() & _budgetAlive(b))
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
      .watch();

  /// Closed budgets (history): `archivedAt` set, not trashed, most recently
  /// closed first (HU-11).
  Stream<List<Budget>> watchArchivedBudgets() => (_db.select(_db.budgets)
        ..where((b) => b.archivedAt.isNotNull() & _budgetAlive(b))
        ..orderBy([(b) => OrderingTerm.desc(b.archivedAt)]))
      .watch();

  Stream<Budget?> watchBudget(String id) =>
      (_db.select(_db.budgets)..where((b) => b.id.equals(id) & _budgetAlive(b)))
          .watchSingleOrNull();

  Future<Budget?> getBudget(String id) =>
      (_db.select(_db.budgets)..where((b) => b.id.equals(id) & _budgetAlive(b)))
          .getSingleOrNull();

  Future<Budget> insertBudget(BudgetsCompanion companion) =>
      _db.into(_db.budgets).insertReturning(companion);

  Future<Budget?> updateBudget(String id, BudgetsCompanion companion) =>
      (_db.update(_db.budgets)..where((b) => b.id.equals(id) & _budgetAlive(b)))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Removes the row for real. Only used to roll back a creation whose scope
  /// write failed: the row is seconds old and nothing references it.
  Future<void> hardDeleteBudget(String id) =>
      (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();

  // -- Scope -----------------------------------------------------------------

  /// Account scope rows of every budget (alive join rows), with a `referentAlive`
  /// flag (account exists and is not tombstoned). Keeping deleted referents is
  /// what lets the domain tell global from emptied-scope.
  Stream<List<BudgetScopeRefRow>> watchScopeAccounts() {
    final query = _db.select(_db.budgetAccounts).join([
      leftOuterJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.budgetAccounts.accountId) &
            _db.accounts.tombstonedAt.isNull(),
      ),
    ])
      ..where(
        _db.budgetAccounts.deletedAt.isNull() &
            _db.budgetAccounts.tombstonedAt.isNull(),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetScopeRefRow(
                budgetId: row.readTable(_db.budgetAccounts).budgetId,
                refId: row.readTable(_db.budgetAccounts).accountId,
                referentAlive: row.readTableOrNull(_db.accounts) != null,
              ),
          ],
        );
  }

  /// Category scope rows of every budget, with `referentAlive` (category exists
  /// and is neither trashed nor tombstoned).
  Stream<List<BudgetScopeRefRow>> watchScopeCategories() {
    final query = _db.select(_db.budgetCategories).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.budgetCategories.categoryId) &
            _db.categories.deletedAt.isNull() &
            _db.categories.tombstonedAt.isNull(),
      ),
    ])
      ..where(
        _db.budgetCategories.deletedAt.isNull() &
            _db.budgetCategories.tombstonedAt.isNull(),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetScopeRefRow(
                budgetId: row.readTable(_db.budgetCategories).budgetId,
                refId: row.readTable(_db.budgetCategories).categoryId,
                referentAlive: row.readTableOrNull(_db.categories) != null,
              ),
          ],
        );
  }

  /// Alive categories (for the subcategory-expansion map). Deleted/tombstoned
  /// categories are excluded so a scoped root never expands to a dead child.
  Stream<List<Category>> watchAliveCategories() => (_db.select(_db.categories)
        ..where((c) => c.deletedAt.isNull() & c.tombstonedAt.isNull()))
      .watch();

  // -- Expenses --------------------------------------------------------------

  /// Every expense that could feed a budget: `type = expense`, not trashed nor
  /// tombstoned, enriched with account and category names. Transfers and income
  /// are excluded here, so they can never count as budget spend.
  Stream<List<BudgetExpenseRow>> watchExpenses() {
    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
    ])
      ..where(
        _db.transactions.type.equalsValue(EntryType.expense) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.tombstonedAt.isNull(),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetExpenseRow(
                id: row.readTable(_db.transactions).id,
                accountId: row.readTable(_db.transactions).accountId,
                categoryId: row.readTable(_db.transactions).categoryId,
                amountMinor: row.readTable(_db.transactions).amountMinor,
                currency: row.readTable(_db.transactions).currency,
                date: row.readTable(_db.transactions).date,
                accountName: row.readTable(_db.accounts).name,
                categoryName: row.readTableOrNull(_db.categories)?.name,
                note: row.readTable(_db.transactions).note,
              ),
          ],
        );
  }

  // -- Scope reconciliation --------------------------------------------------

  /// Rewrites a budget's scope to exactly [accountIds] / [categoryIds] in one
  /// transaction (HU-01/HU-09): inserts the missing rows, and soft-deletes
  /// (`deletedAt`) the ones the user removed — its own trash column, distinct
  /// from a referent being deleted elsewhere. Rows are matched by (budgetId,
  /// refId), reviving a previously removed row instead of duplicating it.
  Future<void> reconcileScope(
    String budgetId, {
    required Set<String> accountIds,
    required Set<String> categoryIds,
    required DateTime now,
  }) =>
      _db.transaction(() async {
        await _reconcileAccounts(budgetId, accountIds, now);
        await _reconcileCategories(budgetId, categoryIds, now);
      });

  Future<void> _reconcileAccounts(
    String budgetId,
    Set<String> accountIds,
    DateTime now,
  ) async {
    final existing = await (_db.select(_db.budgetAccounts)
          ..where((r) => r.budgetId.equals(budgetId) & r.tombstonedAt.isNull()))
        .get();
    final byRef = {for (final row in existing) row.accountId: row};

    for (final accountId in accountIds) {
      final current = byRef[accountId];
      if (current == null) {
        await _db.into(_db.budgetAccounts).insert(
              BudgetAccountsCompanion.insert(
                budgetId: budgetId,
                accountId: accountId,
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );
      } else if (current.deletedAt != null) {
        // Revive a row the user had removed before.
        await (_db.update(_db.budgetAccounts)
              ..where((r) => r.id.equals(current.id)))
            .write(
          BudgetAccountsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }

    for (final row in existing) {
      if (row.deletedAt == null && !accountIds.contains(row.accountId)) {
        await (_db.update(_db.budgetAccounts)..where((r) => r.id.equals(row.id)))
            .write(
          BudgetAccountsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }
  }

  Future<void> _reconcileCategories(
    String budgetId,
    Set<String> categoryIds,
    DateTime now,
  ) async {
    final existing = await (_db.select(_db.budgetCategories)
          ..where((r) => r.budgetId.equals(budgetId) & r.tombstonedAt.isNull()))
        .get();
    final byRef = {for (final row in existing) row.categoryId: row};

    for (final categoryId in categoryIds) {
      final current = byRef[categoryId];
      if (current == null) {
        await _db.into(_db.budgetCategories).insert(
              BudgetCategoriesCompanion.insert(
                budgetId: budgetId,
                categoryId: categoryId,
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );
      } else if (current.deletedAt != null) {
        await (_db.update(_db.budgetCategories)
              ..where((r) => r.id.equals(current.id)))
            .write(
          BudgetCategoriesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }

    for (final row in existing) {
      if (row.deletedAt == null && !categoryIds.contains(row.categoryId)) {
        await (_db.update(_db.budgetCategories)
              ..where((r) => r.id.equals(row.id)))
            .write(
          BudgetCategoriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }
  }

  /// The alive account scope of one budget (surviving referents only) — used to
  /// prefill the edit form.
  Future<List<String>> accountScopeOf(String budgetId) async {
    final query = _db.select(_db.budgetAccounts).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.budgetAccounts.accountId) &
            _db.accounts.tombstonedAt.isNull(),
      ),
    ])
      ..where(
        _db.budgetAccounts.budgetId.equals(budgetId) &
            _db.budgetAccounts.deletedAt.isNull() &
            _db.budgetAccounts.tombstonedAt.isNull(),
      );
    final rows = await query.get();
    return [for (final row in rows) row.readTable(_db.budgetAccounts).accountId];
  }

  /// The alive category scope of one budget — used to prefill the edit form.
  Future<List<String>> categoryScopeOf(String budgetId) async {
    final query = _db.select(_db.budgetCategories).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.budgetCategories.categoryId) &
            _db.categories.deletedAt.isNull() &
            _db.categories.tombstonedAt.isNull(),
      ),
    ])
      ..where(
        _db.budgetCategories.budgetId.equals(budgetId) &
            _db.budgetCategories.deletedAt.isNull() &
            _db.budgetCategories.tombstonedAt.isNull(),
      );
    final rows = await query.get();
    return [
      for (final row in rows) row.readTable(_db.budgetCategories).categoryId,
    ];
  }

  Expression<bool> _budgetAlive($BudgetsTable b) =>
      b.deletedAt.isNull() & b.tombstonedAt.isNull();
}
