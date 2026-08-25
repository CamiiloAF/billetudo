import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/date_range.dart';
import '../models/cashflow_row.dart';
import '../models/category_row.dart';
import '../models/net_worth_row.dart';

/// Drift queries for Gráficas e informes (`docs/requirements/fase-1/10-graficas-informes.md`).
///
/// Every aggregate here is a real SQL `SUM`/`GROUP BY` (criterion 21: "toda
/// agregación en SQL vía Drift, nunca iterando en Dart") — the one deliberate
/// exception is the debt-ledger side of patrimonio (HU-02), which returns raw
/// rows instead: it must reuse `DebtEventRules.cashEventEffect` /
/// `DebtBalanceCalculator` (criterion 7) to avoid a second, divergent
/// implementation of the debt sign rules, and that logic lives in Dart, not
/// SQL. Those raw-row queries are still bounded by date/alive filters in SQL,
/// never an unbounded table scan.
@lazySingleton
class ReportsLocalDatasource {
  const ReportsLocalDatasource(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------
  // Shared filters
  // ---------------------------------------------------------------------

  Expression<bool> _aliveTx($TransactionsTable t) =>
      t.deletedAt.isNull() & t.tombstonedAt.isNull();

  /// The "Reglas de conteo" account filter shared by HU-01/HU-03: the owning
  /// account must not be tombstoned, and archived accounts are always
  /// excluded there (no toggle, unlike HU-02).
  Expression<bool> _inScopeAccount($AccountsTable a) =>
      a.tombstonedAt.isNull() & a.archived.equals(false);

  /// HU-02's own account scope: same tombstone rule, but the archived filter
  /// is conditional on the "incluir cuentas archivadas" toggle.
  Expression<bool> _netWorthScopeAccount(
    $AccountsTable a, {
    required bool includeArchived,
  }) =>
      a.tombstonedAt.isNull() &
      (includeArchived ? const Constant(true) : a.archived.equals(false));

  /// The Gráficas account filter (criterion 4/5): **inclusive-empty**, same
  /// shape as `TransactionFilter.accountIds` — an empty set means "no filter
  /// on this dimension" (every in-scope account), never "match nothing".
  /// Applied per-query against whichever account column that query already
  /// joins on (origin vs. destination for patrimonio's two independent
  /// legs), so a transfer with one leg in the selection and one out still
  /// contributes only the in-scope leg — matching how `includeArchived`
  /// already treats those two legs independently.
  Expression<bool> _accountFilter(
    Expression<String> accountIdColumn,
    Set<String> accountIds,
  ) =>
      accountIds.isEmpty
          ? const Constant(true)
          : accountIdColumn.isIn(accountIds);

  /// Buckets by the device's local wall-clock date, never UTC: `Transactions
  /// .date` is stored as a unix timestamp, and `strftime` on it without a
  /// `localtime` modifier reads day/month boundaries in UTC — which shifts a
  /// transaction into the wrong bucket for any user west or east of UTC near
  /// midnight. `DateTimeModifier.localTime()` converts to the SQLite
  /// engine's local timezone (the device's) before formatting, matching
  /// "Fechas y agregación" → "el corte de periodo usa la zona horaria local
  /// del dispositivo" (docs/requirements/fase-1/10-graficas-informes.md).
  Expression<String> _bucketKeyExpr(
    Expression<DateTime> date,
    DateGranularity granularity,
  ) =>
      date.modify(const DateTimeModifier.localTime()).strftime(
            granularity == DateGranularity.monthly ? '%Y-%m' : '%Y-%m-%d',
          );

  Expression<int> _sumWhen(Expression<bool> when, Expression<int> amount) =>
      CaseWhenExpression<int>(
        cases: [CaseWhen(when, then: amount)],
        orElse: const Constant(0),
      ).sum();

  // ---------------------------------------------------------------------
  // HU-06: earliest data point, to clamp the requested range against.
  // ---------------------------------------------------------------------

  /// Earliest `date` among alive transactions of an in-scope (non-archived,
  /// non-tombstoned) account. `null` when there is none.
  Stream<DateTime?> watchEarliestDataDate() {
    final min = _db.transactions.date.min();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
    ])
      ..addColumns([min])
      ..where(_aliveTx(_db.transactions) & _inScopeAccount(_db.accounts));
    return query.map((row) => row.read(min)).watchSingleOrNull();
  }

  // ---------------------------------------------------------------------
  // HU-01: flujo de caja
  // ---------------------------------------------------------------------

  /// One row per bucket in `[start, endExclusive)`, with income/expense split
  /// by whether the transaction carries a `debtId` (see "Reglas de conteo").
  /// A transfer only ever contributes to `expenseMinor`, via
  /// `countsInBudget`.
  Stream<List<CashflowRow>> watchCashflowBuckets({
    required DateTime start,
    required DateTime endExclusive,
    required DateGranularity granularity,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;
    final bucketKey = _bucketKeyExpr(t.date, granularity);

    final isIncomeNonDebt =
        t.type.equalsValue(EntryType.income) & t.debtId.isNull();
    final isExpenseNonDebt =
        t.type.equalsValue(EntryType.expense) & t.debtId.isNull();
    final isCountedTransfer =
        t.type.equalsValue(EntryType.transfer) & t.countsInBudget.equals(true);
    final isDebtIncome =
        t.type.equalsValue(EntryType.income) & t.debtId.isNotNull();
    final isDebtExpense =
        t.type.equalsValue(EntryType.expense) & t.debtId.isNotNull();

    final incomeSum = _sumWhen(isIncomeNonDebt, t.amountMinor);
    final expenseSum = _sumWhen(isExpenseNonDebt, t.amountMinor);
    final transferSum = _sumWhen(isCountedTransfer, t.amountMinor);
    final debtIncomeSum = _sumWhen(isDebtIncome, t.amountMinor);
    final debtExpenseSum = _sumWhen(isDebtExpense, t.amountMinor);

    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.accountId)),
    ])
      ..addColumns([
        bucketKey,
        incomeSum,
        expenseSum,
        transferSum,
        debtIncomeSum,
        debtExpenseSum,
      ])
      ..where(
        _aliveTx(t) &
            _inScopeAccount(a) &
            _accountFilter(t.accountId, accountIds) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(endExclusive) &
            (isIncomeNonDebt |
                isExpenseNonDebt |
                isCountedTransfer |
                isDebtIncome |
                isDebtExpense),
      )
      ..groupBy([bucketKey]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              CashflowRow(
                bucketKey: row.read(bucketKey)!,
                incomeMinor: row.read(incomeSum) ?? 0,
                expenseMinor:
                    (row.read(expenseSum) ?? 0) + (row.read(transferSum) ?? 0),
                debtIncomeMinor: row.read(debtIncomeSum) ?? 0,
                debtExpenseMinor: row.read(debtExpenseSum) ?? 0,
              ),
          ],
        );
  }

  // ---------------------------------------------------------------------
  // HU-02: patrimonio — líquido side (account balances)
  //
  // A balance's point-in-time value is `initialBalanceMinor` (static) + the
  // signed effect of every alive transaction up to that date. That effect has
  // two independent sources that must be summed separately, because they are
  // scoped by two different accounts (a transfer's origin and destination can
  // be in or out of scope independently, e.g. one archived and the other
  // not): the account losing money as the `accountId` side (any type,
  // negative unless `income`) and the account receiving it as the
  // `transferAccountId` side (`transfer` only, always positive).
  // ---------------------------------------------------------------------

  /// Σ `initialBalanceMinor` over in-scope accounts — the static part of the
  /// baseline every point-in-time balance is built from.
  Stream<int> watchAccountsOpeningBalanceSum({
    required bool includeArchived,
    required Set<String> accountIds,
  }) {
    final sum = _db.accounts.initialBalanceMinor.sum();
    final query = _db.selectOnly(_db.accounts)
      ..addColumns([sum])
      ..where(
        _netWorthScopeAccount(_db.accounts, includeArchived: includeArchived) &
            _accountFilter(_db.accounts.id, accountIds),
      );
    return query.map((row) => row.read(sum) ?? 0).watchSingle();
  }

  Expression<int> _originEffect($TransactionsTable t) =>
      CaseWhenExpression<int>(
        cases: [
          CaseWhen(t.type.equalsValue(EntryType.income), then: t.amountMinor),
        ],
        orElse: -t.amountMinor,
      );

  /// Σ signed effect of the `accountId` (origin) side of every alive
  /// transaction dated before [before], for in-scope accounts.
  Stream<int> watchOriginEffectBefore(
    DateTime before, {
    required bool includeArchived,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;
    final effect = _originEffect(t).sum();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.accountId)),
    ])
      ..addColumns([effect])
      ..where(
        _aliveTx(t) &
            _netWorthScopeAccount(a, includeArchived: includeArchived) &
            _accountFilter(t.accountId, accountIds) &
            t.date.isSmallerThanValue(before),
      );
    return query.map((row) => row.read(effect) ?? 0).watchSingle();
  }

  /// Σ signed effect of the `transferAccountId` (destination) side of every
  /// alive transfer dated before [before], for in-scope accounts. Always
  /// positive (money arriving).
  Stream<int> watchDestinationEffectBefore(
    DateTime before, {
    required bool includeArchived,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;
    final sum = t.amountMinor.sum();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.transferAccountId)),
    ])
      ..addColumns([sum])
      ..where(
        _aliveTx(t) &
            t.type.equalsValue(EntryType.transfer) &
            _netWorthScopeAccount(a, includeArchived: includeArchived) &
            _accountFilter(t.transferAccountId, accountIds) &
            t.date.isSmallerThanValue(before),
      );
    return query.map((row) => row.read(sum) ?? 0).watchSingle();
  }

  /// Bucketed Σ signed effect of the origin side, one row per non-empty
  /// bucket in `[start, endExclusive)`.
  Stream<List<AccountBalanceBucketRow>> watchOriginEffectBuckets({
    required DateTime start,
    required DateTime endExclusive,
    required DateGranularity granularity,
    required bool includeArchived,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;
    final bucketKey = _bucketKeyExpr(t.date, granularity);
    final effect = _originEffect(t).sum();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.accountId)),
    ])
      ..addColumns([bucketKey, effect])
      ..where(
        _aliveTx(t) &
            _netWorthScopeAccount(a, includeArchived: includeArchived) &
            _accountFilter(t.accountId, accountIds) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(endExclusive),
      )
      ..groupBy([bucketKey]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              AccountBalanceBucketRow(
                bucketKey: row.read(bucketKey)!,
                deltaMinor: row.read(effect) ?? 0,
              ),
          ],
        );
  }

  /// Bucketed Σ signed effect of the destination side, one row per non-empty
  /// bucket in `[start, endExclusive)`.
  Stream<List<AccountBalanceBucketRow>> watchDestinationEffectBuckets({
    required DateTime start,
    required DateTime endExclusive,
    required DateGranularity granularity,
    required bool includeArchived,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;
    final bucketKey = _bucketKeyExpr(t.date, granularity);
    final sum = t.amountMinor.sum();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.transferAccountId)),
    ])
      ..addColumns([bucketKey, sum])
      ..where(
        _aliveTx(t) &
            t.type.equalsValue(EntryType.transfer) &
            _netWorthScopeAccount(a, includeArchived: includeArchived) &
            _accountFilter(t.transferAccountId, accountIds) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(endExclusive),
      )
      ..groupBy([bucketKey]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              AccountBalanceBucketRow(
                bucketKey: row.read(bucketKey)!,
                deltaMinor: row.read(sum) ?? 0,
              ),
          ],
        );
  }

  // ---------------------------------------------------------------------
  // HU-02: patrimonio — deuda side (raw rows, see class doc)
  // ---------------------------------------------------------------------

  /// Every alive debt (`deletedAt`/`tombstonedAt` null) — the universe the
  /// point-in-time ledger reconstruction runs over.
  Stream<List<Debt>> watchAliveDebts() => (_db.select(_db.debts)
        ..where((d) => d.deletedAt.isNull() & d.tombstonedAt.isNull()))
      .watch();

  /// Every alive `DebtEntry` dated before [endExclusive] — bounded to the
  /// series' own end, never the whole table's history beyond what a chart
  /// could ever need.
  Stream<List<DebtEntry>> watchDebtEntriesBefore(DateTime endExclusive) =>
      (_db.select(_db.debtEntries)
            ..where(
              (e) =>
                  e.deletedAt.isNull() &
                  e.tombstonedAt.isNull() &
                  e.entryDate.isSmallerThanValue(endExclusive),
            ))
          .watch();

  /// Every alive cash `Transaction` linked to a debt, dated before
  /// [endExclusive].
  Stream<List<Transaction>> watchDebtCashEventsBefore(DateTime endExclusive) =>
      (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.debtId.isNotNull() &
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull() &
                  t.date.isSmallerThanValue(endExclusive),
            ))
          .watch();

  // ---------------------------------------------------------------------
  // HU-03: estructura de gasto
  // ---------------------------------------------------------------------

  /// Σ amount per `categoryId` (nullable = "Sin categoría") within
  /// `[start, endExclusive)`, following the HU-03 counted set: normal gasto,
  /// `countsInBudget` transfers (origin side) and every debt-linked movement
  /// (regardless of `type`, per "Reglas de conteo").
  Stream<List<CategoryExpenseRow>> watchCategoryExpenseRows({
    required DateTime start,
    required DateTime endExclusive,
    required Set<String> accountIds,
  }) {
    final t = _db.transactions;
    final a = _db.accounts;

    final isExpenseNonDebt =
        t.type.equalsValue(EntryType.expense) & t.debtId.isNull();
    final isCountedTransfer =
        t.type.equalsValue(EntryType.transfer) & t.countsInBudget.equals(true);
    final isDebtMovement = t.debtId.isNotNull();
    final counted = isExpenseNonDebt | isCountedTransfer | isDebtMovement;

    final sum = t.amountMinor.sum();
    final count = t.id.count();
    final query = _db.selectOnly(_db.transactions).join([
      innerJoin(a, a.id.equalsExp(t.accountId)),
    ])
      ..addColumns([t.categoryId, sum, count])
      ..where(
        _aliveTx(t) &
            _inScopeAccount(a) &
            _accountFilter(t.accountId, accountIds) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(endExclusive) &
            counted,
      )
      ..groupBy([t.categoryId]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              CategoryExpenseRow(
                categoryId: row.read(t.categoryId),
                amountMinor: row.read(sum) ?? 0,
                movementCount: row.read(count) ?? 0,
              ),
          ],
        );
  }

  /// Category metadata (name/icon/color/parentId) for the given ids, used to
  /// roll [CategoryExpenseRow]s up into the root/subcategory tree. Not
  /// filtered by `deletedAt`: a trashed category must still label a
  /// historical expense correctly.
  Future<List<Category>> getCategoriesByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (_db.select(_db.categories)..where((c) => c.id.isIn(ids))).get();
  }
}
