import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for the Deudas feature: `Debts` and `DebtEntries` CRUD, plus
/// the read side of the cash `Transaction`s that carry a debt id.
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`/`TransactionsLocalDatasource`: no new tables get
/// declared here (the schema already holds them at v14), so it forces no code
/// regeneration.
///
/// It returns **raw rows**, never sums: the balance rule (which sign each event
/// carries) is domain logic with a single home in `DebtBalanceCalculator`. SQL
/// only narrows which rows are read.
///
/// Deletion: a debt uses `deletedAt` (reversible trash, HU-05), never
/// `tombstonedAt` — the soft delete keeps the row alive so the cash
/// `Transaction`s that reference it stay valid. `DebtEntries` are hidden with
/// their debt; cash `Transaction`s are not (they were real account movements).
@lazySingleton
class DebtsLocalDatasource {
  const DebtsLocalDatasource(this._db);

  final AppDatabase _db;

  Expression<bool> _aliveDebt(Debts d) =>
      d.deletedAt.isNull() & d.tombstonedAt.isNull();

  Expression<bool> _aliveEntry(DebtEntries e) =>
      e.deletedAt.isNull() & e.tombstonedAt.isNull();

  Expression<bool> _aliveCashEvent(Transactions t) =>
      t.debtId.isNotNull() & t.deletedAt.isNull() & t.tombstonedAt.isNull();

  // -- List streams (all active debts and every event that belongs to one) --

  Stream<List<Debt>> watchActiveDebts() =>
      (_db.select(_db.debts)
            ..where(_aliveDebt)
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .watch();

  Stream<List<DebtEntry>> watchActiveDebtEntries() =>
      (_db.select(_db.debtEntries)..where(_aliveEntry)).watch();

  Stream<List<Transaction>> watchActiveDebtCashEvents() =>
      (_db.select(_db.transactions)..where(_aliveCashEvent)).watch();

  /// Every non-tombstoned scheduled payment linked to some debt as its cuota
  /// (HU-03), across all debts, ordered by `nextDate` ascending so the list can
  /// group by `debtId` keeping the nearest upcoming cuota per debt. The
  /// list-wide sibling of [watchLinkedInstallment]; same table and filter, so
  /// the card badge matches what the detail shows.
  Stream<List<ScheduledPayment>> watchActiveLinkedInstallments() =>
      (_db.select(_db.scheduledPayments)
            ..where((s) => s.debtId.isNotNull() & s.tombstonedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.nextDate)]))
          .watch();

  // -- Detail streams (one debt) --

  Stream<Debt?> watchDebt(String id) =>
      (_db.select(_db.debts)..where((d) => d.id.equals(id) & _aliveDebt(d)))
          .watchSingleOrNull();

  Stream<List<DebtEntry>> watchDebtEntries(String debtId) =>
      (_db.select(_db.debtEntries)
            ..where((e) => e.debtId.equals(debtId) & _aliveEntry(e)))
          .watch();

  Stream<List<Transaction>> watchDebtCashEvents(String debtId) =>
      (_db.select(_db.transactions)
            ..where((t) => t.debtId.equals(debtId) & _aliveCashEvent(t)))
          .watch();

  /// The scheduled payment linked to [debtId] as its cuota (HU-03), if any.
  /// Reads the shared `ScheduledPayments` table directly — same pattern as the
  /// cash-event query over `Transactions`, no new table is declared here.
  /// Excludes tombstoned templates; when more than one is linked (should not
  /// happen — a debt configures a single cuota), the earliest `nextDate` wins,
  /// so the card shows the nearest upcoming cuota.
  Stream<ScheduledPayment?> watchLinkedInstallment(String debtId) =>
      (_db.select(_db.scheduledPayments)
            ..where(
              (s) => s.debtId.equals(debtId) & s.tombstonedAt.isNull(),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.nextDate)])
            ..limit(1))
          .watchSingleOrNull();

  // -- One-shot reads --

  Future<Debt?> getDebt(String id) =>
      (_db.select(_db.debts)..where((d) => d.id.equals(id) & _aliveDebt(d)))
          .getSingleOrNull();

  Future<List<DebtEntry>> getDebtEntries(String debtId) =>
      (_db.select(_db.debtEntries)
            ..where((e) => e.debtId.equals(debtId) & _aliveEntry(e)))
          .get();

  Future<List<Transaction>> getDebtCashEvents(String debtId) =>
      (_db.select(_db.transactions)
            ..where((t) => t.debtId.equals(debtId) & _aliveCashEvent(t)))
          .get();

  /// The `entryDate` of the newest `interestAccrual` entry, or null when the
  /// debt has never accrued interest.
  Future<DateTime?> lastAccrualDate(String debtId) async {
    final row = await (_db.select(_db.debtEntries)
          ..where(
            (e) =>
                e.debtId.equals(debtId) &
                e.kind.equalsValue(DebtEntryKind.interestAccrual) &
                _aliveEntry(e),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.entryDate)])
          ..limit(1))
        .getSingleOrNull();
    return row?.entryDate;
  }

  // -- Writes --

  Future<Debt> insertDebt(DebtsCompanion companion) =>
      _db.into(_db.debts).insertReturning(companion);

  /// Every normal edit funnels through here with the "alive" guard: a trashed
  /// debt must not be silently mutated by anything but [restoreDebt]. No match
  /// returns null, which the repository turns into a `NotFoundFailure`.
  Future<Debt?> updateDebt(String id, DebtsCompanion companion) =>
      (_db.update(_db.debts)..where((d) => d.id.equals(id) & _aliveDebt(d)))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-05: undo from the trash. Guards only `tombstonedAt IS NULL`; the row
  /// being restored is by definition currently `deletedAt IS NOT NULL`.
  Future<Debt?> restoreDebt(String id, DebtsCompanion companion) =>
      (_db.update(_db.debts)
            ..where((d) => d.id.equals(id) & d.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Cascades the debt's soft-delete state onto its `DebtEntries` (HU-05: the
  /// solo-deuda entries hide with the debt). [deletedAt] null restores them.
  Future<void> setEntriesDeletedAt(
    String debtId, {
    required DateTime? deletedAt,
    required int updatedAt,
  }) =>
      (_db.update(_db.debtEntries)
            ..where((e) => e.debtId.equals(debtId) & e.tombstonedAt.isNull()))
          .write(
        DebtEntriesCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(updatedAt),
        ),
      );

  Future<DebtEntry> insertEntry(DebtEntriesCompanion companion) =>
      _db.into(_db.debtEntries).insertReturning(companion);

  Future<Transaction> insertCashEvent(TransactionsCompanion companion) =>
      _db.into(_db.transactions).insertReturning(companion);

  /// Reads a transaction ignoring the debt filter, to validate a link target.
  Future<Transaction?> getTransaction(String id) => (_db.select(_db.transactions)
        ..where((t) => t.id.equals(id) & t.deletedAt.isNull() & t.tombstonedAt.isNull()))
      .getSingleOrNull();

  Future<Transaction?> linkTransaction(
    String transactionId,
    TransactionsCompanion companion,
  ) =>
      (_db.update(_db.transactions)
            ..where(
              (t) =>
                  t.id.equals(transactionId) &
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull(),
            ))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Item 2: inserts the debt (with `principalMinor == 0`) and its opening
  /// `disbursement` movement in a single transaction, then points the debt's
  /// `initialTransactionId` at that movement. Atomic — the composite only
  /// exists all-at-once, so the derived balance can never observe a debt
  /// without its opening movement (or vice-versa). [movementCompanion] must not
  /// carry a `debtId`; it is stamped here with the just-created debt's id.
  Future<Debt> createDebtWithOpeningMovement({
    required DebtsCompanion debtCompanion,
    required TransactionsCompanion movementCompanion,
    required int updatedAt,
  }) =>
      _db.transaction(() async {
        final debt = await _db.into(_db.debts).insertReturning(debtCompanion);
        final movement = await _db.into(_db.transactions).insertReturning(
              movementCompanion.copyWith(debtId: Value(debt.id)),
            );
        final rows = await (_db.update(_db.debts)
              ..where((d) => d.id.equals(debt.id)))
            .writeReturning(
          DebtsCompanion(
            initialTransactionId: Value(movement.id),
            updatedAt: Value(updatedAt),
          ),
        );
        return rows.first;
      });

  /// Item 2 (retro-link): inserts the opening `disbursement` movement (which
  /// already carries the debt id) and, in the same transaction, moves the debt
  /// to `principalMinor == 0` with `initialTransactionId` pointing at it. The
  /// "alive" guard mirrors [updateDebt]. No match returns null.
  Future<Debt?> attributeOpeningToAccount({
    required String debtId,
    required TransactionsCompanion movementCompanion,
    required int updatedAt,
  }) =>
      _db.transaction(() async {
        final movement =
            await _db.into(_db.transactions).insertReturning(movementCompanion);
        final rows = await (_db.update(_db.debts)
              ..where((d) => d.id.equals(debtId) & _aliveDebt(d)))
            .writeReturning(
          DebtsCompanion(
            principalMinor: const Value(0),
            initialTransactionId: Value(movement.id),
            updatedAt: Value(updatedAt),
          ),
        );
        return rows.isEmpty ? null : rows.first;
      });

  /// Item 2b: updates a linked opening movement's amount and type (the type
  /// changes only when the debt's direction flipped). Same "alive" guard as
  /// [linkTransaction]. No match returns null.
  Future<Transaction?> updateTransactionAmountAndType({
    required String transactionId,
    required int amountMinor,
    required EntryType type,
    required int updatedAt,
  }) =>
      (_db.update(_db.transactions)
            ..where(
              (t) =>
                  t.id.equals(transactionId) &
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull(),
            ))
          .writeReturning(
            TransactionsCompanion(
              amountMinor: Value(amountMinor),
              type: Value(type),
              updatedAt: Value(updatedAt),
            ),
          )
          .then((rows) => rows.isEmpty ? null : rows.first);
}
