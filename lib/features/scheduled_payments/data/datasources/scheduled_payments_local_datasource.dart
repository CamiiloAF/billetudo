import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// A scheduled payment template row together with the (non-tombstoned)
/// account/category/transfer-account rows a list item or the detail screen
/// needs to render, plus how many of its occurrences are currently awaiting
/// resolution (`pending` or `snoozed`, HU-03/HU-07). Data-layer type: it
/// never leaves `data/`.
class ScheduledPaymentRowWithJoins {
  const ScheduledPaymentRowWithJoins({
    required this.scheduledPayment,
    required this.account,
    this.transferAccount,
    this.category,
    this.debt,
    this.pendingOccurrenceCount = 0,
    this.nextAwaitingDate,
    this.lastPaymentDate,
  });

  final ScheduledPayment scheduledPayment;
  final Account account;
  final Account? transferAccount;
  final Category? category;

  /// The owning debt when this template is a cuota (`scheduledPayment.debtId`
  /// is set, HU-03). Only resolved by [ScheduledPaymentsLocalDatasource.watchScheduledPaymentRow]
  /// (the detail query); null in the list queries, which do not render the
  /// cross-link.
  final Debt? debt;

  final int pendingOccurrenceCount;

  /// Effective date of the nearest occurrence still awaiting resolution
  /// (`snoozedToDate ?? occurrenceDate`) — a payment posponed ahead, so the
  /// active card shows this instead of the template cursor. Null when nothing
  /// is awaiting. Only resolved for the "Activos" filter.
  final DateTime? nextAwaitingDate;

  /// Effective date of the newest `confirmed` occurrence, only resolved for
  /// the "Terminados" filter (null everywhere else).
  final DateTime? lastPaymentDate;
}

/// A pending/snoozed occurrence row together with its template and the
/// template's current account/category/transfer-account rows.
class OccurrenceRowWithJoins {
  const OccurrenceRowWithJoins({
    required this.occurrence,
    required this.scheduledPayment,
    required this.account,
    this.transferAccount,
    this.category,
    this.debt,
  });

  final ScheduledPaymentOccurrence occurrence;
  final ScheduledPayment scheduledPayment;
  final Account account;
  final Account? transferAccount;
  final Category? category;

  /// The owning debt when the template is a cuota (`scheduledPayment.debtId`
  /// is set, HU-03) — carries `startDate`, the floor the confirmation sheet's
  /// date picker enforces. Null (via the left join) for an ordinary payment.
  final Debt? debt;
}

/// Drift queries for the Pagos Programados feature: template CRUD, the
/// occurrence ledger (HU-02/HU-03/HU-07), and the generation history
/// (HU-05).
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`: no new tables get declared here, no forced
/// schema regeneration.
@lazySingleton
class ScheduledPaymentsLocalDatasource {
  const ScheduledPaymentsLocalDatasource(this._db);

  final AppDatabase _db;

  /// Statuses that still await user action (HU-03/HU-07): a `snoozed`
  /// occurrence has moved date but is not resolved, so it stays actionable
  /// (confirm/skip) exactly like `pending`.
  Expression<bool> get _awaitingResolution =>
      _db.scheduledPaymentOccurrences.status
          .equalsValue(ScheduledOccurrenceStatus.pending) |
      _db.scheduledPaymentOccurrences.status
          .equalsValue(ScheduledOccurrenceStatus.snoozed);

  /// A template still generates future occurrences (HU-04) when: not
  /// tombstoned (HU-05), not past its `endDate`, and — for a `once`
  /// template — it has not already fired (tracked in the occurrence ledger,
  /// since `ScheduledPayments` has no column of its own for it).
  Expression<bool> _activeExpr() {
    final onceAlreadyFired = existsQuery(
      _db.selectOnly(_db.scheduledPaymentOccurrences)
        ..addColumns([_db.scheduledPaymentOccurrences.id])
        ..where(
          _db.scheduledPaymentOccurrences.scheduledPaymentId
                  .equalsExp(_db.scheduledPayments.id) &
              _db.scheduledPaymentOccurrences.status
                  .equalsValue(ScheduledOccurrenceStatus.confirmed),
        ),
    );

    return _db.scheduledPayments.tombstonedAt.isNull() &
        (_db.scheduledPayments.endDate.isNull() |
            _db.scheduledPayments.nextDate
                .isSmallerOrEqual(_db.scheduledPayments.endDate)) &
        (_db.scheduledPayments.frequency
                .equalsValue(ScheduleFrequency.once)
                .not() |
            onceAlreadyFired.not());
  }

  // -- Templates --------------------------------------------------------

  Future<ScheduledPayment> insertScheduledPayment(
    ScheduledPaymentsCompanion companion,
  ) =>
      _db.into(_db.scheduledPayments).insertReturning(companion);

  Future<ScheduledPayment?> getScheduledPayment(String id) =>
      (_db.select(_db.scheduledPayments)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  /// The owning debt's `startDate` (nullable, see `Debts.startDate`), for the
  /// confirmation floor of a cuota (HU-03): a confirmed occurrence must never
  /// generate a movement dated before the debt began. Returns null when the
  /// debt has no recorded start or the id does not resolve.
  Future<DateTime?> getDebtStartDate(String debtId) {
    final query = _db.selectOnly(_db.debts)
      ..addColumns([_db.debts.startDate])
      ..where(_db.debts.id.equals(debtId));
    return query
        .map((row) => row.read(_db.debts.startDate))
        .getSingleOrNull();
  }

  /// Only guards `tombstonedAt IS NULL`: a deleted template cannot be
  /// edited (HU-05).
  Future<ScheduledPayment?> updateScheduledPayment(
    String id,
    ScheduledPaymentsCompanion companion,
  ) =>
      (_db.update(_db.scheduledPayments)
            ..where((s) => s.id.equals(id) & s.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  Future<ScheduledPayment?> tombstoneScheduledPayment(
    String id,
    ScheduledPaymentsCompanion companion,
  ) =>
      (_db.update(_db.scheduledPayments)
            ..where((s) => s.id.equals(id) & s.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Every active template that still generates occurrences (HU-02), for
  /// the catch-up run. Not joined: the generator only needs the template's
  /// own fields.
  Future<List<ScheduledPayment>> getActiveTemplatesForCatchup() =>
      (_db.select(_db.scheduledPayments)..where((_) => _activeExpr())).get();

  /// HU-04: active templates ordered by `nextDate` ascending, enriched with
  /// display names and how many occurrences of each are awaiting
  /// resolution.
  Stream<List<ScheduledPaymentRowWithJoins>> watchActiveScheduledPayments() {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');
    // Only DUE awaiting occurrences hide a card and move it to "Por confirmar".
    // Counting future ones here (a snooze always moves an occurrence forward;
    // "Confirmar ahora" can materialize a future one) hid the card while "Por
    // confirmar" — which filters by due date — never showed it, so the whole
    // template vanished. This due filter mirrors `GetPendingOccurrences`
    // (`isDueOn`) exactly, so a card hides only when it truly has something to
    // confirm today.
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    final effectiveDate = coalesce<DateTime>([
      _db.scheduledPaymentOccurrences.snoozedToDate,
      _db.scheduledPaymentOccurrences.occurrenceDate,
    ]);
    final pendingCount = _db.scheduledPaymentOccurrences.id.count(
      filter: _awaitingResolution &
          effectiveDate.isSmallerThanValue(startOfTomorrow),
    );
    // The nearest still-awaiting occurrence's effective date. When a card is
    // shown (no DUE occurrence), this is a future one — e.g. a payment posponed
    // ahead — so the card must display that date, not the template cursor.
    final nextAwaitingDate = effectiveDate.min(filter: _awaitingResolution);

    final query = _db.select(_db.scheduledPayments).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.scheduledPayments.accountId),
      ),
      leftOuterJoin(
        transferAccounts,
        transferAccounts.id.equalsExp(_db.scheduledPayments.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
      leftOuterJoin(
        _db.scheduledPaymentOccurrences,
        _db.scheduledPaymentOccurrences.scheduledPaymentId
            .equalsExp(_db.scheduledPayments.id),
      ),
    ])
      ..addColumns([pendingCount, nextAwaitingDate])
      ..where(_activeExpr())
      ..groupBy([_db.scheduledPayments.id])
      ..orderBy([OrderingTerm.asc(_db.scheduledPayments.nextDate)]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              ScheduledPaymentRowWithJoins(
                scheduledPayment: row.readTable(_db.scheduledPayments),
                account: row.readTable(_db.accounts),
                transferAccount: row.readTableOrNull(transferAccounts),
                category: row.readTableOrNull(_db.categories),
                pendingOccurrenceCount: row.read(pendingCount) ?? 0,
                nextAwaitingDate: row.read(nextAwaitingDate),
              ),
          ],
        );
  }

  /// The "Terminados" filter: the same join as [watchActiveScheduledPayments]
  /// but for templates that no longer generate occurrences (the negation of
  /// [_activeExpr], still excluding tombstoned ones from a fresh "recién
  /// vencido" narrative — a deleted template belongs to HU-05's detail link,
  /// not to this list), ordered by `nextDate` descending.
  ///
  /// Also resolves each template's last real payment: the newest effective
  /// date (`snoozedToDate` when the occurrence was moved, `occurrenceDate`
  /// otherwise) among its `confirmed` occurrences. That is the card's
  /// "Último pago", which is not the template's `endDate`.
  Stream<List<ScheduledPaymentRowWithJoins>> watchFinishedScheduledPayments() {
    final transferAccounts =
        _db.alias(_db.accounts, 'finished_transfer_accounts');
    final lastPaymentDate = coalesce([
      _db.scheduledPaymentOccurrences.snoozedToDate,
      _db.scheduledPaymentOccurrences.occurrenceDate,
    ]).max(
      filter: _db.scheduledPaymentOccurrences.status
          .equalsValue(ScheduledOccurrenceStatus.confirmed),
    );

    final query = _db.select(_db.scheduledPayments).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.scheduledPayments.accountId),
      ),
      leftOuterJoin(
        transferAccounts,
        transferAccounts.id.equalsExp(_db.scheduledPayments.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
      leftOuterJoin(
        _db.scheduledPaymentOccurrences,
        _db.scheduledPaymentOccurrences.scheduledPaymentId
            .equalsExp(_db.scheduledPayments.id),
      ),
    ])
      ..addColumns([lastPaymentDate])
      ..where(_activeExpr().not() & _db.scheduledPayments.tombstonedAt.isNull())
      ..groupBy([_db.scheduledPayments.id])
      ..orderBy([OrderingTerm.desc(_db.scheduledPayments.nextDate)]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              ScheduledPaymentRowWithJoins(
                scheduledPayment: row.readTable(_db.scheduledPayments),
                account: row.readTable(_db.accounts),
                transferAccount: row.readTableOrNull(transferAccounts),
                category: row.readTableOrNull(_db.categories),
                lastPaymentDate: row.read(lastPaymentDate),
              ),
          ],
        );
  }

  /// HU-05: the same join as [watchActiveScheduledPayments], narrowed to one
  /// id and without the "active" filter — a tombstoned template must still
  /// be viewable from a generated transaction's historical link.
  Stream<ScheduledPaymentRowWithJoins?> watchScheduledPaymentRow(String id) {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');

    final query = _db.select(_db.scheduledPayments).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.scheduledPayments.accountId),
      ),
      leftOuterJoin(
        transferAccounts,
        transferAccounts.id.equalsExp(_db.scheduledPayments.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
      // The owning debt when this template is a cuota (HU-03 cross-link). A
      // left join: an ordinary template has a null `debtId` and reads no row.
      leftOuterJoin(
        _db.debts,
        _db.debts.id.equalsExp(_db.scheduledPayments.debtId),
      ),
    ])
      ..where(_db.scheduledPayments.id.equals(id))
      // Make the stream depend on THIS template's occurrences: snooze/confirm/
      // skip write to `scheduledPaymentOccurrences`, not `scheduledPayments`,
      // so without this the detail's próximo-pago date (which is derived from
      // the nearest awaiting occurrence) would stay stale until the template
      // row itself changed. This scalar `EXISTS` never adds a row; it only
      // registers the occurrences table as a watched dependency.
      ..addColumns([
        existsQuery(
          _db.selectOnly(_db.scheduledPaymentOccurrences)
            ..addColumns([_db.scheduledPaymentOccurrences.id])
            ..where(
              _db.scheduledPaymentOccurrences.scheduledPaymentId
                  .equalsExp(_db.scheduledPayments.id),
            ),
        ),
        // Same reason for THIS template's transactions: deleting/restoring a
        // generated transaction must refresh the combined "Historial" (it is
        // read from the transactions table), else a trashed row lingers and
        // reopening it fails to load.
        existsQuery(
          _db.selectOnly(_db.transactions)
            ..addColumns([_db.transactions.id])
            ..where(
              _db.transactions.scheduledPaymentId
                  .equalsExp(_db.scheduledPayments.id),
            ),
        ),
      ]);

    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      return ScheduledPaymentRowWithJoins(
        scheduledPayment: row.readTable(_db.scheduledPayments),
        account: row.readTable(_db.accounts),
        transferAccount: row.readTableOrNull(transferAccounts),
        category: row.readTableOrNull(_db.categories),
        debt: row.readTableOrNull(_db.debts),
      );
    });
  }

  // -- Occurrence ledger --------------------------------------------------

  Future<ScheduledPaymentOccurrence?> getOccurrence(String id) =>
      (_db.select(_db.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(id)))
          .getSingleOrNull();

  Future<ScheduledPaymentOccurrence?> getOccurrenceForDate(
    String scheduledPaymentId,
    DateTime occurrenceDate,
  ) =>
      (_db.select(_db.scheduledPaymentOccurrences)
            ..where(
              (o) =>
                  o.scheduledPaymentId.equals(scheduledPaymentId) &
                  o.occurrenceDate.equals(occurrenceDate),
            ))
          .getSingleOrNull();

  /// The earliest occurrence still awaiting resolution for [scheduledPaymentId]
  /// (HU-05's "próximo pago" when in manual mode), by effective date.
  Future<ScheduledPaymentOccurrence?> getNextAwaitingOccurrence(
    String scheduledPaymentId,
  ) async {
    final rows = await (_db.select(_db.scheduledPaymentOccurrences)
          ..where(
            (o) =>
                o.scheduledPaymentId.equals(scheduledPaymentId) &
                _awaitingResolution,
          ))
        .get();
    if (rows.isEmpty) {
      return null;
    }
    DateTime effectiveOf(ScheduledPaymentOccurrence o) =>
        o.snoozedToDate ?? o.occurrenceDate;
    rows.sort((a, b) => effectiveOf(a).compareTo(effectiveOf(b)));
    return rows.first;
  }

  Future<ScheduledPaymentOccurrence> insertOccurrence(
    ScheduledPaymentOccurrencesCompanion companion,
  ) =>
      _db.into(_db.scheduledPaymentOccurrences).insertReturning(companion);

  Future<ScheduledPaymentOccurrence?> updateOccurrence(
    String id,
    ScheduledPaymentOccurrencesCompanion companion,
  ) =>
      (_db.update(_db.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(id)))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  Future<void> deleteOccurrence(String id) => (_db.delete(
        _db.scheduledPaymentOccurrences,
      )..where((o) => o.id.equals(id)))
          .go();

  /// Removes every occurrence of [scheduledPaymentId] still awaiting
  /// resolution (`pending` or `snoozed`). Used when the user manually edits a
  /// template's date (HU-05): the outstanding occurrence materialized for the
  /// old due date (e.g. a "vence hoy" pending one) would otherwise keep driving
  /// the "próximo pago" the detail/list show, masking the freshly edited
  /// `nextDate` (item 18). Only unresolved rows are touched — `confirmed` and
  /// `skipped` occurrences are history and never removed.
  Future<void> deleteAwaitingOccurrences(String scheduledPaymentId) =>
      (_db.delete(_db.scheduledPaymentOccurrences)
            ..where(
              (o) =>
                  o.scheduledPaymentId.equals(scheduledPaymentId) &
                  (o.status.equalsValue(ScheduledOccurrenceStatus.pending) |
                      o.status
                          .equalsValue(ScheduledOccurrenceStatus.snoozed)),
            ))
          .go();

  /// HU-03/HU-04: every occurrence still awaiting resolution, across every
  /// template, ordered by effective due date ascending.
  Stream<List<OccurrenceRowWithJoins>> watchPendingOccurrences() {
    final transferAccounts = _db.alias(_db.accounts, 'transfer_accounts');

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
        transferAccounts,
        transferAccounts.id.equalsExp(_db.scheduledPayments.transferAccountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.scheduledPayments.categoryId),
      ),
      // The owning debt when the template is a cuota (HU-03): its `startDate`
      // is the floor the confirmation sheet must not let the date fall below.
      // A left join — an ordinary template has a null `debtId` and reads no row.
      leftOuterJoin(
        _db.debts,
        _db.debts.id.equalsExp(_db.scheduledPayments.debtId),
      ),
    ])
      ..where(_awaitingResolution)
      ..orderBy([
        OrderingTerm.asc(
          coalesce<DateTime>([
            _db.scheduledPaymentOccurrences.snoozedToDate,
            _db.scheduledPaymentOccurrences.occurrenceDate,
          ]),
        ),
      ]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              OccurrenceRowWithJoins(
                occurrence: row.readTable(_db.scheduledPaymentOccurrences),
                scheduledPayment: row.readTable(_db.scheduledPayments),
                account: row.readTable(_db.accounts),
                transferAccount: row.readTableOrNull(transferAccounts),
                category: row.readTableOrNull(_db.categories),
                debt: row.readTableOrNull(_db.debts),
              ),
          ],
        );
  }

  // -- Generated transactions / history -----------------------------------

  /// Inserts the transaction a confirmed occurrence generates. The
  /// `Transactions` table is shared infrastructure (like `Tags`), not owned
  /// by any single feature, so this feature writes to it directly instead
  /// of routing through Transacciones' data layer.
  Future<Transaction> insertGeneratedTransaction(
    TransactionsCompanion companion,
  ) =>
      _db.into(_db.transactions).insertReturning(companion);

  /// HU-01/03: copies the template's current tags onto a freshly generated
  /// transaction — a one-time copy, not a live link (criterion 3).
  Future<void> copyTemplateTagsToTransaction({
    required String scheduledPaymentId,
    required String transactionId,
    required DateTime now,
  }) async {
    final tagIds = await tagIdsForScheduledPayment(scheduledPaymentId);
    for (final tagId in tagIds) {
      await _db.into(_db.transactionTags).insert(
            TransactionTagsCompanion.insert(
              transactionId: transactionId,
              tagId: tagId,
              createdAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
    }
  }

  Future<List<String>> tagIdsForScheduledPayment(String scheduledPaymentId) {
    final query = _db.selectOnly(_db.scheduledPaymentTags)
      ..addColumns([_db.scheduledPaymentTags.tagId])
      ..where(
        _db.scheduledPaymentTags.scheduledPaymentId.equals(scheduledPaymentId) &
            _db.scheduledPaymentTags.deletedAt.isNull() &
            _db.scheduledPaymentTags.tombstonedAt.isNull(),
      );
    return query.map((row) => row.read(_db.scheduledPaymentTags.tagId)!).get();
  }

  /// HU-05 / page spec "Historial con omitidos": first page / "cargar más" of
  /// a template's history, most recent first — confirmed transactions
  /// (`source: scheduled`) and `skipped` occurrences interleaved by effective
  /// date.
  ///
  /// Pagination spans BOTH sources: each is fetched up to `offset + limit`
  /// rows (already ordered), merged, then sliced to the requested window. A
  /// deterministic secondary sort by id keeps ties (same date) stable across
  /// pages. Bounded work: at most `offset + limit` rows per source.
  Future<List<ScheduledHistoryRow>> getHistory(
    String scheduledPaymentId, {
    required int offset,
    required int limit,
  }) async {
    final window = offset + limit;
    final skippedEffectiveDate = coalesce<DateTime>([
      _db.scheduledPaymentOccurrences.snoozedToDate,
      _db.scheduledPaymentOccurrences.occurrenceDate,
    ]);

    final txRows = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.scheduledPaymentId.equals(scheduledPaymentId) &
                // `deletedAt` too, not just `tombstonedAt`: a trashed
                // transaction is excluded from its own detail/list (their
                // `_alive` guard), so showing it here would open a detail that
                // can't load it ("We couldn't load your transactions").
                t.deletedAt.isNull() &
                t.tombstonedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(window))
        .get();

    final skippedRows = await (_db.select(_db.scheduledPaymentOccurrences)
          ..where(
            (o) =>
                o.scheduledPaymentId.equals(scheduledPaymentId) &
                o.status.equalsValue(ScheduledOccurrenceStatus.skipped),
          )
          ..orderBy([(_) => OrderingTerm.desc(skippedEffectiveDate)])
          ..limit(window))
        .get();

    final merged = <ScheduledHistoryRow>[
      for (final t in txRows) ScheduledConfirmedHistoryRow(t),
      for (final o in skippedRows) ScheduledSkippedHistoryRow(o),
    ]..sort((a, b) {
        final byDate = b.effectiveDate.compareTo(a.effectiveDate);
        if (byDate != 0) {
          return byDate;
        }
        return b.sortKey.compareTo(a.sortKey);
      });

    if (offset >= merged.length) {
      return const <ScheduledHistoryRow>[];
    }
    final end = window > merged.length ? merged.length : window;
    return merged.sublist(offset, end);
  }

  /// Combined count for "Ver historial completo (N)": confirmed transactions
  /// plus skipped occurrences.
  Future<int> countHistory(String scheduledPaymentId) async {
    final confirmed = await countGeneratedTransactions(scheduledPaymentId);
    final skippedCount = _db.scheduledPaymentOccurrences.id.count();
    final skippedQuery = _db.selectOnly(_db.scheduledPaymentOccurrences)
      ..addColumns([skippedCount])
      ..where(
        _db.scheduledPaymentOccurrences.scheduledPaymentId
                .equals(scheduledPaymentId) &
            _db.scheduledPaymentOccurrences.status
                .equalsValue(ScheduledOccurrenceStatus.skipped),
      );
    final skippedRow = await skippedQuery.getSingle();
    return confirmed + (skippedRow.read(skippedCount) ?? 0);
  }

  /// How many transactions this template has actually generated — the subset
  /// of [countHistory] that drives `once`'s "already fired" fact, kept
  /// separate so a skipped `once` (no transaction) never reads as executed.
  Future<int> countGeneratedTransactions(String scheduledPaymentId) async {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(
        _db.transactions.scheduledPaymentId.equals(scheduledPaymentId) &
            _db.transactions.deletedAt.isNull() &
            _db.transactions.tombstonedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}

/// One row of the combined detail history (data layer only). A confirmed
/// transaction or a skipped occurrence, both Drift rows — never leaves `data/`.
sealed class ScheduledHistoryRow {
  const ScheduledHistoryRow();

  /// The date the row is sorted/displayed by.
  DateTime get effectiveDate;

  /// A stable secondary sort key so same-date rows keep a deterministic order
  /// across paginated calls.
  String get sortKey;
}

class ScheduledConfirmedHistoryRow extends ScheduledHistoryRow {
  const ScheduledConfirmedHistoryRow(this.transaction);

  final Transaction transaction;

  @override
  DateTime get effectiveDate => transaction.date;

  @override
  String get sortKey => transaction.id;
}

class ScheduledSkippedHistoryRow extends ScheduledHistoryRow {
  const ScheduledSkippedHistoryRow(this.occurrence);

  final ScheduledPaymentOccurrence occurrence;

  @override
  DateTime get effectiveDate =>
      occurrence.snoozedToDate ?? occurrence.occurrenceDate;

  @override
  String get sortKey => occurrence.id;
}
