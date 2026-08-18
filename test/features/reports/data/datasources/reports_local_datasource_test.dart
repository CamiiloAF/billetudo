import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the "Reglas de conteo" of `docs/requirements/fase-1/10-graficas-informes.md`
/// against a real (in-memory) schema, for every SQL-aggregated query
/// `ReportsLocalDatasource` exposes.
void main() {
  late AppDatabase database;
  late ReportsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = ReportsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  Future<Account> createAccount({
    String name = 'Efectivo',
    bool archived = false,
    DateTime? tombstonedAt,
    int initialBalanceMinor = 0,
  }) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
              archived: Value(archived),
              tombstonedAt: Value(tombstonedAt),
              initialBalanceMinor: Value(initialBalanceMinor),
            ),
          );

  Future<Category> createCategory(
    String name, {
    CategoryKind kind = CategoryKind.expense,
    String? parentId,
  }) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(
              name: name,
              kind: kind,
              parentId: Value(parentId),
            ),
          );

  Future<Transaction> createTx({
    required String accountId,
    required EntryType type,
    required int amountMinor,
    required DateTime date,
    String? categoryId,
    String? transferAccountId,
    bool countsInBudget = false,
    String? debtId,
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      database.into(database.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: Value(categoryId),
              amountMinor: amountMinor,
              currency: 'COP',
              type: type,
              date: date,
              transferAccountId: Value(transferAccountId),
              countsInBudget: Value(countsInBudget),
              debtId: Value(debtId),
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
              updatedAt: const Value(0),
            ),
          );

  Future<Debt> createDebt({
    DebtDirection direction = DebtDirection.iOwe,
    int principalMinor = 0,
    DateTime? startDate,
  }) =>
      database.into(database.debts).insertReturning(
            DebtsCompanion.insert(
              name: 'Préstamo',
              direction: direction,
              principalMinor: principalMinor,
              currency: 'COP',
              startDate: Value(startDate ?? DateTime(2026)),
              updatedAt: const Value(0),
            ),
          );

  group('watchCashflowBuckets', () {
    test('a transfer without countsInBudget is excluded entirely', () async {
      final origin = await createAccount(name: 'Origen');
      final dest = await createAccount(name: 'Destino');
      await createTx(
        accountId: origin.id,
        type: EntryType.transfer,
        amountMinor: 10000,
        date: DateTime(2026, 7, 10),
        transferAccountId: dest.id,
      );

      final rows = await datasource.watchCashflowBuckets(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
        accountIds: const {},
      ).first;

      expect(rows, isEmpty);
    });

    test(
      'a transfer with countsInBudget counts once, as expense of the origin',
      () async {
        final origin = await createAccount(name: 'Origen');
        final dest = await createAccount(name: 'Destino');
        final category = await createCategory('Ahorros');
        await createTx(
          accountId: origin.id,
          type: EntryType.transfer,
          amountMinor: 10000,
          date: DateTime(2026, 7, 10),
          transferAccountId: dest.id,
          countsInBudget: true,
          categoryId: category.id,
        );

        final rows = await datasource.watchCashflowBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          accountIds: const {},
        ).first;

        expect(rows, hasLength(1));
        expect(rows.single.incomeMinor, 0);
        expect(rows.single.expenseMinor, 10000);
      },
    );

    test('a debt-linked movement counts by default (income/expense)', () async {
      final account = await createAccount();
      final debt = await createDebt();
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 5000,
        date: DateTime(2026, 7, 10),
        debtId: debt.id,
      );

      final rows = await datasource.watchCashflowBuckets(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
        accountIds: const {},
      ).first;

      expect(rows, hasLength(1));
      // Debt movements are returned in their own field so the repository can
      // merge or segregate them per the toggle — never folded silently into
      // the non-debt figure by the datasource itself.
      expect(rows.single.debtExpenseMinor, 5000);
      expect(rows.single.expenseMinor, 0);
    });

    test('deleted/tombstoned transactions and archived accounts are excluded',
        () async {
      final alive = await createAccount(name: 'Activa');
      final archived = await createAccount(name: 'Archivada', archived: true);
      final tombstonedAccount =
          await createAccount(name: 'Lápida', tombstonedAt: DateTime(2026));

      await createTx(
        accountId: alive.id,
        type: EntryType.expense,
        amountMinor: 100,
        date: DateTime(2026, 7, 5),
        deletedAt: DateTime(2026, 7, 6),
      );
      await createTx(
        accountId: alive.id,
        type: EntryType.expense,
        amountMinor: 200,
        date: DateTime(2026, 7, 5),
        tombstonedAt: DateTime(2026, 7, 6),
      );
      await createTx(
        accountId: archived.id,
        type: EntryType.expense,
        amountMinor: 300,
        date: DateTime(2026, 7, 5),
      );
      await createTx(
        accountId: tombstonedAccount.id,
        type: EntryType.expense,
        amountMinor: 400,
        date: DateTime(2026, 7, 5),
      );

      final rows = await datasource.watchCashflowBuckets(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
        accountIds: const {},
      ).first;

      expect(rows, isEmpty);
    });

    test('buckets by day when granularity is daily', () async {
      final account = await createAccount();
      await createTx(
        accountId: account.id,
        type: EntryType.income,
        amountMinor: 1000,
        date: DateTime(2026, 7, 5),
      );
      await createTx(
        accountId: account.id,
        type: EntryType.income,
        amountMinor: 2000,
        date: DateTime(2026, 7, 6),
      );

      final rows = await datasource.watchCashflowBuckets(
        start: DateTime(2026, 7, 5),
        endExclusive: DateTime(2026, 7, 7),
        granularity: DateGranularity.daily,
        accountIds: const {},
      ).first;

      expect(rows, hasLength(2));
      expect(rows.map((r) => r.bucketKey),
          containsAll(['2026-07-05', '2026-07-06']));
    });

    test(
      'buckets by the device local date, not UTC, near a month boundary',
      () async {
        // Local wall-clock 2026-07-31 23:00 is 2026-08-01 in UTC for any
        // timezone west of UTC (e.g. America/Bogotá, UTC-5). Bucketing by
        // UTC would misfile this into August; "Fechas y agregación" requires
        // it to stay in July, the device's local month. Only meaningful
        // where the test runner's own local timezone differs from UTC.
        if (DateTime.now().timeZoneOffset == Duration.zero) {
          return;
        }
        final account = await createAccount();
        await createTx(
          accountId: account.id,
          type: EntryType.expense,
          amountMinor: 5000,
          date: DateTime(2026, 7, 31, 23),
        );

        final rows = await datasource.watchCashflowBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          accountIds: const {},
        ).first;

        expect(rows, hasLength(1));
        expect(rows.single.bucketKey, '2026-07');
      },
    );
  });

  group('watchCategoryExpenseRows', () {
    test('a debt movement with no category falls in the null bucket', () async {
      final account = await createAccount();
      final debt = await createDebt();
      await createTx(
        accountId: account.id,
        type: EntryType.income, // disbursement, still counted as gasto here
        amountMinor: 7000,
        date: DateTime(2026, 7, 10),
        debtId: debt.id,
      );

      final rows = await datasource.watchCategoryExpenseRows(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        accountIds: const {},
      ).first;

      expect(rows, hasLength(1));
      expect(rows.single.categoryId, isNull);
      expect(rows.single.amountMinor, 7000);
      expect(rows.single.movementCount, 1);
    });

    test('normal expense groups by its own categoryId', () async {
      final account = await createAccount();
      final category = await createCategory('Mercado');
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 3000,
        date: DateTime(2026, 7, 10),
        categoryId: category.id,
      );
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 2000,
        date: DateTime(2026, 7, 11),
        categoryId: category.id,
      );

      final rows = await datasource.watchCategoryExpenseRows(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        accountIds: const {},
      ).first;

      expect(rows, hasLength(1));
      expect(rows.single.categoryId, category.id);
      expect(rows.single.amountMinor, 5000);
      expect(rows.single.movementCount, 2);
    });

    test('an uncounted transfer never appears', () async {
      final origin = await createAccount(name: 'Origen');
      final dest = await createAccount(name: 'Destino');
      await createTx(
        accountId: origin.id,
        type: EntryType.transfer,
        amountMinor: 4000,
        date: DateTime(2026, 7, 10),
        transferAccountId: dest.id,
      );

      final rows = await datasource.watchCategoryExpenseRows(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        accountIds: const {},
      ).first;

      expect(rows, isEmpty);
    });
  });

  group('watchAliveDebts / watchDebtEntriesBefore / watchDebtCashEventsBefore',
      () {
    test(
        'DebtEntries never leak into cashflow or category queries, but are '
        'exposed for patrimonio', () async {
      final debt = await createDebt(principalMinor: 100000);
      await database.into(database.debtEntries).insertReturning(
            DebtEntriesCompanion.insert(
              debtId: debt.id,
              kind: DebtEntryKind.interestAccrual,
              amountMinor: 500,
              entryDate: DateTime(2026, 7, 15),
              updatedAt: const Value(0),
            ),
          );

      final cashflowRows = await datasource.watchCashflowBuckets(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
        accountIds: const {},
      ).first;
      final categoryRows = await datasource.watchCategoryExpenseRows(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        accountIds: const {},
      ).first;
      final entries =
          await datasource.watchDebtEntriesBefore(DateTime(2026, 8)).first;

      expect(cashflowRows, isEmpty);
      expect(categoryRows, isEmpty);
      expect(entries, hasLength(1));
    });
  });

  group('watchAccountsOpeningBalanceSum / effect queries (patrimonio)', () {
    test('both liquid inputs are available and archived accounts are opt-in',
        () async {
      final active = await createAccount(
        name: 'Activa',
        initialBalanceMinor: 100000,
      );
      final archived = await createAccount(
        name: 'Archivada',
        archived: true,
        initialBalanceMinor: 50000,
      );
      await createTx(
        accountId: active.id,
        type: EntryType.income,
        amountMinor: 20000,
        date: DateTime(2026, 7, 10),
      );
      await createTx(
        accountId: archived.id,
        type: EntryType.income,
        amountMinor: 9000,
        date: DateTime(2026, 7, 10),
      );

      final openingExcluding = await datasource.watchAccountsOpeningBalanceSum(
        includeArchived: false,
        accountIds: const {},
      ).first;
      final openingIncluding = await datasource.watchAccountsOpeningBalanceSum(
        includeArchived: true,
        accountIds: const {},
      ).first;
      final originBeforeExcluding = await datasource.watchOriginEffectBefore(
        DateTime(2026, 8),
        includeArchived: false,
        accountIds: const {},
      ).first;
      final originBeforeIncluding = await datasource.watchOriginEffectBefore(
        DateTime(2026, 8),
        includeArchived: true,
        accountIds: const {},
      ).first;

      expect(openingExcluding, 100000);
      expect(openingIncluding, 150000);
      expect(originBeforeExcluding, 20000);
      expect(originBeforeIncluding, 29000);
    });

    test('a transfer moves the delta from origin to destination', () async {
      final origin = await createAccount(name: 'Origen');
      final dest = await createAccount(name: 'Destino');
      await createTx(
        accountId: origin.id,
        type: EntryType.transfer,
        amountMinor: 15000,
        date: DateTime(2026, 7, 10),
        transferAccountId: dest.id,
      );

      final originBefore = await datasource.watchOriginEffectBefore(
        DateTime(2026, 8),
        includeArchived: false,
        accountIds: const {},
      ).first;
      final destBefore = await datasource.watchDestinationEffectBefore(
        DateTime(2026, 8),
        includeArchived: false,
        accountIds: const {},
      ).first;

      expect(originBefore, -15000);
      expect(destBefore, 15000);
      // Between two in-scope accounts, the net effect on total liquid is 0.
      expect(originBefore + destBefore, 0);
    });

    test(
      'accountIds (criterion 5) scopes each leg independently: the origin '
      'query filters by accountId, the destination query by '
      'transferAccountId',
      () async {
        final origin = await createAccount(name: 'Origen');
        final dest = await createAccount(name: 'Destino');
        final other = await createAccount(name: 'Otra');
        await createTx(
          accountId: origin.id,
          type: EntryType.transfer,
          amountMinor: 15000,
          date: DateTime(2026, 7, 10),
          transferAccountId: dest.id,
        );
        await createTx(
          accountId: other.id,
          type: EntryType.income,
          amountMinor: 500,
          date: DateTime(2026, 7, 10),
        );

        final originOnlyOther = await datasource.watchOriginEffectBefore(
          DateTime(2026, 8),
          includeArchived: false,
          accountIds: {other.id},
        ).first;
        final originOnlyOrigin = await datasource.watchOriginEffectBefore(
          DateTime(2026, 8),
          includeArchived: false,
          accountIds: {origin.id},
        ).first;
        final destOnlyDest = await datasource.watchDestinationEffectBefore(
          DateTime(2026, 8),
          includeArchived: false,
          accountIds: {dest.id},
        ).first;
        final destOnlyOther = await datasource.watchDestinationEffectBefore(
          DateTime(2026, 8),
          includeArchived: false,
          accountIds: {other.id},
        ).first;

        expect(originOnlyOther, 500);
        expect(originOnlyOrigin, -15000);
        expect(destOnlyDest, 15000);
        expect(destOnlyOther, 0);

        final openingSum = await datasource.watchAccountsOpeningBalanceSum(
          includeArchived: false,
          accountIds: {origin.id},
        ).first;
        expect(openingSum, 0);
      },
    );

    test(
      'accountIds (criterion 4) also scopes the bucketed cashflow and '
      'category queries',
      () async {
        final selected = await createAccount(name: 'Seleccionada');
        final excluded = await createAccount(name: 'Excluida');
        final category = await createCategory('Mercado');
        await createTx(
          accountId: selected.id,
          type: EntryType.expense,
          amountMinor: 5000,
          date: DateTime(2026, 7, 10),
          categoryId: category.id,
        );
        await createTx(
          accountId: excluded.id,
          type: EntryType.expense,
          amountMinor: 9000,
          date: DateTime(2026, 7, 10),
          categoryId: category.id,
        );

        final cashflowRows = await datasource.watchCashflowBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          accountIds: {selected.id},
        ).first;
        final categoryRows = await datasource.watchCategoryExpenseRows(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          accountIds: {selected.id},
        ).first;

        expect(cashflowRows, hasLength(1));
        expect(cashflowRows.single.expenseMinor, 5000);
        expect(categoryRows, hasLength(1));
        expect(categoryRows.single.amountMinor, 5000);
      },
    );

    test(
      'accountIds (criterion 5) also scopes the bucketed origin/destination '
      'effect queries',
      () async {
        final origin = await createAccount(name: 'Origen');
        final dest = await createAccount(name: 'Destino');
        await createTx(
          accountId: origin.id,
          type: EntryType.transfer,
          amountMinor: 15000,
          date: DateTime(2026, 7, 10),
          transferAccountId: dest.id,
        );

        final originBuckets = await datasource.watchOriginEffectBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          includeArchived: false,
          accountIds: {origin.id},
        ).first;
        final originBucketsExcluded = await datasource.watchOriginEffectBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          includeArchived: false,
          accountIds: {dest.id},
        ).first;
        final destBuckets = await datasource.watchDestinationEffectBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          includeArchived: false,
          accountIds: {dest.id},
        ).first;
        final destBucketsExcluded =
            await datasource.watchDestinationEffectBuckets(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
          includeArchived: false,
          accountIds: {origin.id},
        ).first;

        expect(originBuckets, hasLength(1));
        expect(originBuckets.single.deltaMinor, -15000);
        expect(originBucketsExcluded, isEmpty);
        expect(destBuckets, hasLength(1));
        expect(destBuckets.single.deltaMinor, 15000);
        expect(destBucketsExcluded, isEmpty);
      },
    );
  });
}
