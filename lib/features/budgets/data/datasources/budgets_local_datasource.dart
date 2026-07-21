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

  /// Hides the row from every read path (`_budgetAlive`) while keeping it in
  /// the table, so `BudgetAccounts`/`BudgetCategories` rows whose FK already
  /// points at it (written by `reconcileScope`) keep a live referent instead
  /// of dangling. Used to cancel a not-yet-active adjustment/resume fork —
  /// see `cancelAmountAdjustment`.
  Future<void> tombstoneBudget(String id, DateTime now) =>
      (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
        BudgetsCompanion(
          tombstonedAt: Value(now),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

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

  // -- Amount adjustment ("fork de 2 o 3 partes") ------------------------------
  //
  // No new column/table: the fork is inferred purely from the exact shape
  // [applyAmountAdjustment]/[applyAmountAdjustmentInPlace] always write — an
  // alive budget whose `startDate` starts the day after another's `endDate`,
  // mirroring its cadence/scope. See `BudgetRepositoryImpl` for the window
  // math that produces those dates.
  //
  // Two shapes exist, both anchored on `currentWindow`:
  //  - `currentWindow.index > 0`: the original closes at the end of the
  //    *previous* cycle, a new "adjusted" row covers `currentWindow` with the
  //    new amount, and a "resume" row picks the original amount back up at
  //    `nextWindow`.
  //  - `currentWindow.index == 0`: there is no previous cycle to close, so
  //    the original row is patched in place (new amount, `endDate` at the end
  //    of `currentWindow`) instead of being closed + forked — it plays the
  //    "adjusted" role itself. Only the "resume" row is inserted.

  /// The pending "this period only" fork of [original], if any.
  ///
  /// Returns either a separate row (the `currentWindow.index > 0` shape) or
  /// [original] itself, when [original]'s own `endDate` closes at the end of
  /// the cycle it is still active in and a resume fork follows it directly
  /// (the `currentWindow.index == 0` in-place shape).
  Future<Budget?> findAdjustedFork(Budget original) async {
    final closesAt = original.endDate;
    if (closesAt == null) {
      return null;
    }
    final nextStart = closesAt.add(const Duration(days: 1));
    final rows = await (_db.select(_db.budgets)
          ..where((b) => b.startDate.equals(nextStart) & _budgetAlive(b)))
        .get();
    for (final row in rows) {
      if (_sameCadence(row, original)) {
        // A forward row whose own cycle never ends is the resume fork: that
        // makes `original` itself the adjusted fork, patched in place
        // (currentWindow.index == 0, no previous period to close). A forward
        // row that does have an endDate is a separate adjusted fork instead
        // (currentWindow.index > 0).
        return row.endDate == null ? original : row;
      }
    }
    return null;
  }

  /// The "resumes the original amount" fork that follows [adjusted], the
  /// same way [findAdjustedFork] finds the adjusted part. [original] is only
  /// used for its cadence fields (name/icon/currency/period/rollover/
  /// threshold), which an adjustment never touches — its `amountMinor` may
  /// already be the *new* amount when [adjusted] is [original] itself
  /// (the in-place shape), so it is deliberately not used to filter here.
  Future<Budget?> findResumeFork(Budget original, Budget adjusted) async {
    final closesAt = adjusted.endDate;
    if (closesAt == null) {
      return null;
    }
    final nextStart = closesAt.add(const Duration(days: 1));
    final rows = await (_db.select(_db.budgets)
          ..where(
            (b) =>
                b.startDate.equals(nextStart) &
                b.endDate.isNull() &
                _budgetAlive(b),
          ))
        .get();
    for (final row in rows) {
      if (_sameCadence(row, original)) {
        return row;
      }
    }
    return null;
  }

  bool _sameCadence(Budget row, Budget original) =>
      row.id != original.id &&
      row.name == original.name &&
      row.icon == original.icon &&
      row.currency == original.currency &&
      row.period == original.period &&
      row.rollover == original.rollover &&
      row.alertThresholdPct == original.alertThresholdPct;

  /// Applies the `currentWindow.index > 0` fork atomically: closes
  /// [originalId] at the end of the *previous* cycle with [closeCompanion],
  /// inserts the adjusted (this-cycle-only) and resume (indefinite) budgets
  /// with the same scope as the original.
  Future<void> applyAmountAdjustment({
    required String originalId,
    required BudgetsCompanion closeCompanion,
    required BudgetsCompanion adjustedCompanion,
    required BudgetsCompanion resumeCompanion,
    required Set<String> accountIds,
    required Set<String> categoryIds,
    required DateTime now,
  }) =>
      _db.transaction(() async {
        await updateBudget(originalId, closeCompanion);
        final adjusted = await insertBudget(adjustedCompanion);
        await reconcileScope(
          adjusted.id,
          accountIds: accountIds,
          categoryIds: categoryIds,
          now: now,
        );
        final resumed = await insertBudget(resumeCompanion);
        await reconcileScope(
          resumed.id,
          accountIds: accountIds,
          categoryIds: categoryIds,
          now: now,
        );
      });

  /// Applies the `currentWindow.index == 0` fork atomically: there is no
  /// previous cycle to close, so [originalId] is patched in place with
  /// [adjustedCompanion] (new amount + `endDate` at the end of the current
  /// cycle) instead of being closed and forked, and only the resume
  /// (indefinite, original amount) budget is inserted, with the same scope.
  Future<void> applyAmountAdjustmentInPlace({
    required String originalId,
    required BudgetsCompanion adjustedCompanion,
    required BudgetsCompanion resumeCompanion,
    required Set<String> accountIds,
    required Set<String> categoryIds,
    required DateTime now,
  }) =>
      _db.transaction(() async {
        await updateBudget(originalId, adjustedCompanion);
        final resumed = await insertBudget(resumeCompanion);
        await reconcileScope(
          resumed.id,
          accountIds: accountIds,
          categoryIds: categoryIds,
          now: now,
        );
      });

  /// Cancels a pending fork atomically, reversing whichever of the two shapes
  /// [applyAmountAdjustment]/[applyAmountAdjustmentInPlace] wrote:
  ///  - `currentWindow.index > 0` ([adjustedId] != [originalId]): tombstones
  ///    the not-yet-active adjusted/resume budgets (never applied, so no
  ///    undo-trash is needed — but `hardDeleteBudget` is not safe here: by
  ///    the time this runs, `reconcileScope` has already written
  ///    `BudgetAccounts`/`BudgetCategories` rows whose FK points at them, and
  ///    physically deleting the referent would orphan those scope rows) and
  ///    reopens the original with [reopenCompanion] (clears `endDate`,
  ///    amount untouched — it was never changed).
  ///  - `currentWindow.index == 0` ([adjustedId] == [originalId]): the
  ///    "adjusted" row *is* the original, so it is left alone here and
  ///    restored via [reopenCompanion] instead (original amount, `endDate:
  ///    null`); only the resume fork is tombstoned.
  /// [resumeId] is `null` only in an inconsistent state (the resume fork went
  /// missing); still cancels what it can find. `_budgetAlive` excludes
  /// tombstoned rows from every read path, so a cancelled fork disappears
  /// from the UI exactly like a hard delete would, without breaking the FK.
  Future<void> cancelAmountAdjustment({
    required String originalId,
    required String adjustedId,
    required String? resumeId,
    required BudgetsCompanion reopenCompanion,
    required DateTime now,
  }) =>
      _db.transaction(() async {
        if (adjustedId != originalId) {
          await tombstoneBudget(adjustedId, now);
        }
        if (resumeId != null) {
          await tombstoneBudget(resumeId, now);
        }
        await updateBudget(originalId, reopenCompanion);
      });

  Expression<bool> _budgetAlive($BudgetsTable b) =>
      b.deletedAt.isNull() & b.tombstonedAt.isNull();
}
