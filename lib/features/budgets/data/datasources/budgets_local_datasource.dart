import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/budget_period_override.dart';
import '../models/budget_period_override_mapper.dart';

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
    this.categoryIcon,
    this.categoryColor,
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
  final String? categoryIcon;
  final String? categoryColor;
  final String? note;
}

/// One income transaction reduced to the "Modo sobres" essentials (HU-06).
/// Data-layer type: never leaves `data/`.
class BudgetIncomeRow {
  const BudgetIncomeRow({
    required this.amountMinor,
    required this.currency,
    required this.date,
  });

  final int amountMinor;
  final String currency;
  final DateTime date;
}

/// An active expense scheduled-payment template eligible for a budget's
/// "programado" segment (HU-12), enriched with the names its row would show.
/// Data-layer type: never leaves `data/`; the repository maps [template] (a
/// raw Drift row) into the domain `ScheduledPayment` entity itself, rather
/// than importing Pagos Programados' `data/` mapper.
class BudgetScheduledTemplateRow {
  const BudgetScheduledTemplateRow({
    required this.template,
    required this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  final ScheduledPayment template;
  final String accountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
}

/// A `pending` occurrence (HU-03 ledger) of an expense scheduled-payment
/// template, eligible for a budget's "programado" segment (HU-12). Data-layer
/// type, same reasoning as [BudgetScheduledTemplateRow].
class BudgetPendingOccurrenceRow {
  const BudgetPendingOccurrenceRow({
    required this.occurrence,
    required this.template,
    required this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  final ScheduledPaymentOccurrence occurrence;
  final ScheduledPayment template;
  final String accountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
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

  /// One-shot alive categories — the fix #14 scope reconciliation needs the
  /// current tree once, not a stream.
  Future<List<Category>> getAliveCategories() => (_db.select(_db.categories)
        ..where((c) => c.deletedAt.isNull() & c.tombstonedAt.isNull()))
      .get();

  /// Ids of the budgets the fix #14 reconciliation should inspect: everything
  /// not tombstoned (active, archived and trashed budgets alike — all could
  /// carry a frozen materialized scope).
  Future<List<String>> reconcilableBudgetIds() async {
    final rows = await (_db.select(_db.budgets)
          ..where((b) => b.tombstonedAt.isNull()))
        .get();
    return [for (final row in rows) row.id];
  }

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
                categoryIcon: row.readTableOrNull(_db.categories)?.icon,
                categoryColor: row.readTableOrNull(_db.categories)?.color,
                note: row.readTable(_db.transactions).note,
              ),
          ],
        );
  }

  /// Every income transaction that can feed the "Modo sobres" summary (HU-06):
  /// `type = income`, not trashed nor tombstoned. The calendar-month filter and
  /// the currency grouping are the domain's job, so this returns the raw rows.
  Stream<List<BudgetIncomeRow>> watchIncome() {
    final query = _db.select(_db.transactions)
      ..where(
        (t) =>
            t.type.equalsValue(EntryType.income) &
            t.deletedAt.isNull() &
            t.tombstonedAt.isNull(),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetIncomeRow(
                amountMinor: row.amountMinor,
                currency: row.currency,
                date: row.date,
              ),
          ],
        );
  }

  // -- Scheduled payments (HU-12) ---------------------------------------------

  /// Active expense scheduled-payment templates that can feed a budget's
  /// "programado" segment: `type = expense`, not tombstoned, and — for a
  /// `once` template that already fired — excluded (its `nextDate` never
  /// advances past the date it already generated, so it must not be
  /// re-projected; same rule `_activeExpr` applies in Pagos Programados,
  /// reselected here rather than imported, per the data-layer boundary).
  /// Enriched with account/category names for display.
  Stream<List<BudgetScheduledTemplateRow>> watchScheduledExpenseTemplates() {
    final query = _db.select(_db.scheduledPayments).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.scheduledPayments.accountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
    ])
      ..where(
        _db.scheduledPayments.type.equalsValue(EntryType.expense) &
            _db.scheduledPayments.tombstonedAt.isNull() &
            (_db.scheduledPayments.frequency
                    .equalsValue(ScheduleFrequency.once)
                    .not() |
                _onceAlreadyFired().not()),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetScheduledTemplateRow(
                template: row.readTable(_db.scheduledPayments),
                accountName: row.readTable(_db.accounts).name,
                categoryName: row.readTableOrNull(_db.categories)?.name,
                categoryIcon: row.readTableOrNull(_db.categories)?.icon,
                categoryColor: row.readTableOrNull(_db.categories)?.color,
              ),
          ],
        );
  }

  /// Whether a template has already generated a `confirmed` occurrence — the
  /// only way a `once` template (whose `nextDate` never advances) must stop
  /// projecting.
  Expression<bool> _onceAlreadyFired() => existsQuery(
        _db.selectOnly(_db.scheduledPaymentOccurrences)
          ..addColumns([_db.scheduledPaymentOccurrences.id])
          ..where(
            _db.scheduledPaymentOccurrences.scheduledPaymentId
                    .equalsExp(_db.scheduledPayments.id) &
                _db.scheduledPaymentOccurrences.status
                    .equalsValue(ScheduledOccurrenceStatus.confirmed),
          ),
      );

  /// Occurrences still `pending` (HU-03) of expense templates, eligible for a
  /// budget's "programado" segment: `confirmed`/`skipped`/`snoozed` ones are
  /// excluded (`snoozed` moves the effective date but is not itself owed, so
  /// HU-12 leaves it out — see
  /// `BudgetProgressCalculator.matchesPendingScheduledOccurrence`).
  Stream<List<BudgetPendingOccurrenceRow>> watchPendingScheduledOccurrences() {
    final query = _db.select(_db.scheduledPaymentOccurrences).join([
      innerJoin(
        _db.scheduledPayments,
        _db.scheduledPayments.id
            .equalsExp(_db.scheduledPaymentOccurrences.scheduledPaymentId),
      ),
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.scheduledPayments.accountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
    ])
      ..where(
        _db.scheduledPaymentOccurrences.status
                .equalsValue(ScheduledOccurrenceStatus.pending) &
            _db.scheduledPayments.type.equalsValue(EntryType.expense) &
            _db.scheduledPayments.tombstonedAt.isNull(),
      );

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              BudgetPendingOccurrenceRow(
                occurrence: row.readTable(_db.scheduledPaymentOccurrences),
                template: row.readTable(_db.scheduledPayments),
                accountName: row.readTable(_db.accounts).name,
                categoryName: row.readTableOrNull(_db.categories)?.name,
                categoryIcon: row.readTableOrNull(_db.categories)?.icon,
                categoryColor: row.readTableOrNull(_db.categories)?.color,
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
        await (_db.update(_db.budgetAccounts)
              ..where((r) => r.id.equals(row.id)))
            .write(
          BudgetAccountsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
      }
    }
  }

  /// Rewrites only the **category** dimension of a budget's scope to exactly
  /// [categoryIds], leaving the account rows untouched — the fix #14
  /// reconciliation only ever changes categories, and must not disturb an
  /// account scope row whose referent was deleted elsewhere.
  Future<void> reconcileCategoryScope(
    String budgetId, {
    required Set<String> categoryIds,
    required DateTime now,
  }) =>
      _db.transaction(
        () => _reconcileCategories(budgetId, categoryIds, now),
      );

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
    return [
      for (final row in rows) row.readTable(_db.budgetAccounts).accountId
    ];
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

  // -- Per-period amount override (Wallet-style) -----------------------------
  //
  // Replaces the old multi-row "fork" model: instead of inserting extra
  // `Budgets` rows for the adjusted/resume periods (which surfaced as duplicate
  // budgets), the budget stays a single row and a per-period amount lives in
  // `BudgetPeriodOverrides`, one row per (budgetId, periodStart). See
  // `BudgetRepositoryImpl` for which window `periodStart` targets (the next
  // one). Cancelling an override is a HARD delete — no trash/undo, nothing
  // references it by FK.

  /// Every override row, mapped to the domain entity, for the list-progress
  /// join. `periodStart` is normalized to date-only by the mapper so it indexes
  /// by equality against `BudgetPeriodWindow.start`.
  Stream<List<BudgetPeriodOverride>> watchBudgetPeriodOverrides() =>
      _db.select(_db.budgetPeriodOverrides).watch().map(
            (rows) => rows.map(BudgetPeriodOverrideMapper.toEntity).toList(),
          );

  /// The override for ([budgetId], [periodStart]) if one exists. [periodStart]
  /// is matched date-only.
  Future<BudgetPeriodOverride?> getPeriodOverride(
    String budgetId,
    DateTime periodStart,
  ) async {
    final start = BudgetPeriodOverrideMapper.dateOnly(periodStart);
    final row = await (_db.select(_db.budgetPeriodOverrides)
          ..where(
            (o) => o.budgetId.equals(budgetId) & o.periodStart.equals(start),
          ))
        .getSingleOrNull();
    return row == null ? null : BudgetPeriodOverrideMapper.toEntity(row);
  }

  /// Inserts a new override for ([budgetId], [periodStart]). The repository has
  /// already checked no override exists for that window (uniqueness), so this
  /// is a plain insert. [periodStart] is stored date-only.
  Future<void> upsertPeriodOverride({
    required String budgetId,
    required DateTime periodStart,
    required int amountMinor,
    required DateTime now,
  }) =>
      _db.into(_db.budgetPeriodOverrides).insert(
            BudgetPeriodOverridesCompanion.insert(
              budgetId: budgetId,
              periodStart: BudgetPeriodOverrideMapper.dateOnly(periodStart),
              amountMinor: amountMinor,
              createdAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );

  /// Rewrites the amount of the existing override for ([budgetId],
  /// [periodStart]), stamping `updatedAt`.
  Future<void> updatePeriodOverrideAmount({
    required String budgetId,
    required DateTime periodStart,
    required int amountMinor,
    required DateTime now,
  }) {
    final start = BudgetPeriodOverrideMapper.dateOnly(periodStart);
    return (_db.update(_db.budgetPeriodOverrides)
          ..where(
            (o) => o.budgetId.equals(budgetId) & o.periodStart.equals(start),
          ))
        .write(
      BudgetPeriodOverridesCompanion(
        amountMinor: Value(amountMinor),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  /// HARD-deletes the override for ([budgetId], [periodStart]) — cancelling an
  /// adjustment. Nothing references it, so there is no trash/undo.
  Future<void> deletePeriodOverride(String budgetId, DateTime periodStart) {
    final start = BudgetPeriodOverrideMapper.dateOnly(periodStart);
    return (_db.delete(_db.budgetPeriodOverrides)
          ..where(
            (o) => o.budgetId.equals(budgetId) & o.periodStart.equals(start),
          ))
        .go();
  }

  Expression<bool> _budgetAlive($BudgetsTable b) =>
      b.deletedAt.isNull() & b.tombstonedAt.isNull();
}
