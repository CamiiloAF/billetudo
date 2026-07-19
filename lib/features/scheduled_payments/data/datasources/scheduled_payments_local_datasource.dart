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
    this.pendingOccurrenceCount = 0,
    this.lastPaymentDate,
  });

  final ScheduledPayment scheduledPayment;
  final Account account;
  final Account? transferAccount;
  final Category? category;
  final int pendingOccurrenceCount;

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
  });

  final ScheduledPaymentOccurrence occurrence;
  final ScheduledPayment scheduledPayment;
  final Account account;
  final Account? transferAccount;
  final Category? category;
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
    final pendingCount = _db.scheduledPaymentOccurrences.id.count(
      filter: _awaitingResolution,
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
      ..addColumns([pendingCount])
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
    ])
      ..where(_db.scheduledPayments.id.equals(id));

    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      return ScheduledPaymentRowWithJoins(
        scheduledPayment: row.readTable(_db.scheduledPayments),
        account: row.readTable(_db.accounts),
        transferAccount: row.readTableOrNull(transferAccounts),
        category: row.readTableOrNull(_db.categories),
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

  /// HU-05: first page / "cargar más" of a template's generated
  /// transactions (`source: scheduled`), most recent first.
  Future<List<Transaction>> getHistory(
    String scheduledPaymentId, {
    required int offset,
    required int limit,
  }) {
    final query = _db.select(_db.transactions)
      ..where(
        (t) =>
            t.scheduledPaymentId.equals(scheduledPaymentId) &
            t.tombstonedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<int> countHistory(String scheduledPaymentId) async {
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.id.count()])
      ..where(
        _db.transactions.scheduledPaymentId.equals(scheduledPaymentId) &
            _db.transactions.tombstonedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(_db.transactions.id.count()) ?? 0;
  }
}
