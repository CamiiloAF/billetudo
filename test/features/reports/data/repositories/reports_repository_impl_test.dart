import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:billetudo/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_point.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/services/resolve_effective_date_range.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ReportsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ReportsRepositoryImpl(
      ReportsLocalDatasource(db),
      const ResolveEffectiveDateRange(),
      const DebtBalanceCalculator(),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => db.close());

  Future<Account> createAccount({
    String name = 'Efectivo',
    int initialBalanceMinor = 0,
    bool archived = false,
  }) =>
      db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
              initialBalanceMinor: Value(initialBalanceMinor),
              archived: Value(archived),
            ),
          );

  Future<Category> createCategory(
    String name, {
    CategoryKind kind = CategoryKind.expense,
    String? parentId,
  }) =>
      db.into(db.categories).insertReturning(
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
  }) =>
      db.into(db.transactions).insertReturning(
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
              updatedAt: const Value(0),
            ),
          );

  Future<Debt> createDebt({
    DebtDirection direction = DebtDirection.iOwe,
    int principalMinor = 0,
    DateTime? startDate,
  }) =>
      db.into(db.debts).insertReturning(
            DebtsCompanion.insert(
              name: 'Préstamo',
              direction: direction,
              principalMinor: principalMinor,
              currency: 'COP',
              startDate: Value(startDate ?? DateTime(2026)),
              updatedAt: const Value(0),
            ),
          );

  group('watchCashflow', () {
    test(
      'debt movements are always returned, both merged and segregated '
      'totals stay consistent (HU-01 toggle never changes the total)',
      () async {
        final account = await createAccount();
        final debt = await createDebt();
        await createTx(
          accountId: account.id,
          type: EntryType.income,
          amountMinor: 500000,
          date: DateTime(2026, 7, 10),
          debtId: debt.id,
        );
        await createTx(
          accountId: account.id,
          type: EntryType.expense,
          amountMinor: 100000,
          date: DateTime(2026, 7, 12),
        );

        final range = DateRange(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
        );

        final integrated = (await repository.watchCashflow(
          range: range,
          includeDebtMovements: true,
          accountIds: const {},
        ).first)
            .getRight()
            .toNullable()!;
        final segregated = (await repository.watchCashflow(
          range: range,
          includeDebtMovements: false,
          accountIds: const {},
        ).first)
            .getRight()
            .toNullable()!;

        // The range is short, so HU-06 may switch to daily buckets — sum
        // across every point instead of assuming a single monthly bucket.
        int netOf(Iterable<CashflowPoint> points) =>
            points.fold<int>(0, (sum, p) => sum + p.netMinor);
        int debtIncomeOf(Iterable<CashflowPoint> points) =>
            points.fold<int>(0, (sum, p) => sum + p.debtIncomeMinor);

        expect(netOf(integrated.points), 400000);
        // The toggle only changes presentation metadata, never the fetched
        // point values or the total.
        expect(netOf(segregated.points), 400000);
        expect(
          debtIncomeOf(segregated.points),
          debtIncomeOf(integrated.points),
        );
      },
    );

    test('an empty range produces an empty (never a faked) series', () async {
      final range = DateRange(
        start: DateTime(2020),
        endExclusive: DateTime(2020, 2),
        granularity: DateGranularity.monthly,
      );

      final result = (await repository.watchCashflow(
        range: range,
        includeDebtMovements: true,
        accountIds: const {},
      ).first)
          .getRight()
          .toNullable()!;

      expect(result.isEmpty, isTrue);
    });
  });

  group('watchNetWorth', () {
    test('exposes both líquido and total series, deuda reduces total only',
        () async {
      final account = await createAccount(initialBalanceMinor: 1000000);
      final debt = await createDebt(
        direction: DebtDirection.iOwe,
        principalMinor: 300000,
        startDate: DateTime(2026, 6, 1),
      );
      // A cash abono in July reduces the debt but must not touch líquido
      // differently than any other expense would.
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 50000,
        date: DateTime(2026, 7, 5),
        debtId: debt.id,
      );

      final range = DateRange(
        start: DateTime(2026, 6),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
      );

      final series = (await repository.watchNetWorth(
        range: range,
        includeArchivedAccounts: false,
        accountIds: const {},
      ).first)
          .getRight()
          .toNullable()!;

      // The range may clamp to a shorter/daily series (HU-06); it always
      // has at least an opening point and one after the movement.
      expect(series.points.length, greaterThanOrEqualTo(2));

      final first = series.points.first;
      // Before any movement: líquido is the account's initial balance;
      // total already reflects the just-opened debt's principal.
      expect(first.liquidMinor, 1000000);
      expect(first.totalMinor, 1000000 - 300000);

      final last = series.points.last;
      // The abono moved 50000 out of the account (líquido drops) and off the
      // debt (outstanding drops by the same amount) — total is unaffected by
      // that single movement, only líquido is.
      expect(last.liquidMinor, 1000000 - 50000);
      expect(last.totalMinor, last.liquidMinor - (300000 - 50000));
    });

    test('archived accounts are excluded from líquido unless included',
        () async {
      await createAccount(initialBalanceMinor: 100000);
      final archived = await createAccount(
        initialBalanceMinor: 40000,
        archived: true,
      );

      final range = DateRange(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
      );

      final excluding = (await repository.watchNetWorth(
        range: range,
        includeArchivedAccounts: false,
        accountIds: const {},
      ).first)
          .getRight()
          .toNullable()!;
      final including = (await repository.watchNetWorth(
        range: range,
        includeArchivedAccounts: true,
        accountIds: const {},
      ).first)
          .getRight()
          .toNullable()!;

      expect(excluding.points.first.liquidMinor, 100000);
      expect(including.points.first.liquidMinor, 140000);
      // Silence unused-variable warning if the account isn't referenced
      // elsewhere in this test.
      expect(archived.archived, isTrue);
    });

    test(
      'accountIds (criterion 5) narrows líquido (opening + effects) but '
      'never the deuda side (criterion 6)',
      () async {
        final selected = await createAccount(
          name: 'Seleccionada',
          initialBalanceMinor: 200000,
        );
        final excluded = await createAccount(
          name: 'Excluida',
          initialBalanceMinor: 50000,
        );
        final debt = await createDebt(
          direction: DebtDirection.iOwe,
          principalMinor: 300000,
          startDate: DateTime(2026, 6, 1),
        );
        await createTx(
          accountId: selected.id,
          type: EntryType.income,
          amountMinor: 10000,
          date: DateTime(2026, 7, 5),
        );
        await createTx(
          accountId: excluded.id,
          type: EntryType.income,
          amountMinor: 999999,
          date: DateTime(2026, 7, 5),
        );

        final range = DateRange(
          start: DateTime(2026, 6),
          endExclusive: DateTime(2026, 8),
          granularity: DateGranularity.monthly,
        );

        final all = (await repository.watchNetWorth(
          range: range,
          includeArchivedAccounts: false,
          accountIds: const {},
        ).first)
            .getRight()
            .toNullable()!;
        final onlySelected = (await repository.watchNetWorth(
          range: range,
          includeArchivedAccounts: false,
          accountIds: {selected.id},
        ).first)
            .getRight()
            .toNullable()!;

        // Líquido narrows to only the selected account's opening + effects.
        expect(all.points.first.liquidMinor, 200000 + 50000);
        expect(onlySelected.points.first.liquidMinor, 200000);
        expect(onlySelected.points.last.liquidMinor, 200000 + 10000);

        // The deuda component of `totalMinor` (liquid - pending) stays
        // identical regardless of the account filter (criterion 6).
        final allDebtComponent =
            all.points.first.totalMinor - all.points.first.liquidMinor;
        final selectedDebtComponent = onlySelected.points.first.totalMinor -
            onlySelected.points.first.liquidMinor;
        expect(selectedDebtComponent, allDebtComponent);
        expect(allDebtComponent, -300000);
        // Silence unused-variable warning.
        expect(debt.direction, DebtDirection.iOwe);
      },
    );
  });

  group('watchCategoryBreakdown', () {
    test(
        'groups subcategories under their root and keeps "Sin categoría" '
        'separate', () async {
      final account = await createAccount();
      final root = await createCategory('Mercado');
      final sub = await createCategory('Restaurantes', parentId: root.id);
      final debt = await createDebt();

      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 20000,
        date: DateTime(2026, 7, 5),
        categoryId: root.id,
      );
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 15000,
        date: DateTime(2026, 7, 6),
        categoryId: sub.id,
      );
      await createTx(
        accountId: account.id,
        type: EntryType.expense,
        amountMinor: 7000,
        date: DateTime(2026, 7, 7),
        debtId: debt.id,
      );

      final range = DateRange(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
      );

      final breakdown = (await repository
              .watchCategoryBreakdown(range: range, accountIds: const {}).first)
          .getRight()
          .toNullable()!;

      expect(breakdown.totalMinor, 42000);
      final rootItem =
          breakdown.items.firstWhere((item) => item.categoryId == root.id);
      expect(rootItem.amountMinor, 35000);
      expect(rootItem.movementCount, 2);
      expect(rootItem.subcategories, hasLength(1));
      expect(rootItem.subcategories.single.amountMinor, 15000);
      expect(rootItem.subcategories.single.movementCount, 1);

      final uncategorized =
          breakdown.items.firstWhere((item) => item.categoryId == null);
      expect(uncategorized.amountMinor, 7000);
      expect(uncategorized.movementCount, 1);
      expect(uncategorized.name, isNull);
    });

    test('accountIds (criterion 4) restricts the breakdown to that account',
        () async {
      final selected = await createAccount(name: 'Seleccionada');
      final excluded = await createAccount(name: 'Excluida');
      final category = await createCategory('Mercado');
      await createTx(
        accountId: selected.id,
        type: EntryType.expense,
        amountMinor: 5000,
        date: DateTime(2026, 7, 5),
        categoryId: category.id,
      );
      await createTx(
        accountId: excluded.id,
        type: EntryType.expense,
        amountMinor: 9000,
        date: DateTime(2026, 7, 5),
        categoryId: category.id,
      );

      final range = DateRange(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
      );

      final all = (await repository
              .watchCategoryBreakdown(range: range, accountIds: const {}).first)
          .getRight()
          .toNullable()!;
      final onlySelected = (await repository.watchCategoryBreakdown(
        range: range,
        accountIds: {selected.id},
      ).first)
          .getRight()
          .toNullable()!;

      expect(all.totalMinor, 14000);
      expect(onlySelected.totalMinor, 5000);
    });

    test(
        // Bug 1 regression: a root category with no expense rows of its own
        // (an active account filter excludes its own direct movements, only
        // a subcategory's rows survive) must still resolve its name/icon —
        // not fall back to the null placeholder.
        'a root category with no direct expense rows of its own still '
        'resolves its name/icon via its subcategory (criterion 4 + no '
        "root's own movements)", () async {
      final rootAccount = await createAccount(name: 'Cuenta raíz');
      final subAccount = await createAccount(name: 'Cuenta sub');
      final root = await createCategory('Hogar');
      final sub = await createCategory('Mercado', parentId: root.id);

      // The root's own movement lives in `rootAccount`, excluded by the
      // active account filter below — only the subcategory's movement (in
      // `subAccount`) survives the filter.
      await createTx(
        accountId: rootAccount.id,
        type: EntryType.expense,
        amountMinor: 20000,
        date: DateTime(2026, 7, 5),
        categoryId: root.id,
      );
      await createTx(
        accountId: subAccount.id,
        type: EntryType.expense,
        amountMinor: 15000,
        date: DateTime(2026, 7, 6),
        categoryId: sub.id,
      );

      final range = DateRange(
        start: DateTime(2026, 7),
        endExclusive: DateTime(2026, 8),
        granularity: DateGranularity.monthly,
      );

      final breakdown = (await repository.watchCategoryBreakdown(
        range: range,
        accountIds: {subAccount.id},
      ).first)
          .getRight()
          .toNullable()!;

      expect(breakdown.totalMinor, 15000);
      final rootItem =
          breakdown.items.firstWhere((item) => item.categoryId == root.id);
      // The root itself has no row in `rows` (its movement was filtered
      // out), only its subcategory does — `name`/`icon` must still resolve.
      // `createCategory` above does not set an icon (nullable column), so
      // the assertion that matters is `name` resolving at all — proof the
      // root row was actually fetched via the backfill, not left as the
      // `categoryById[rootId] == null` placeholder Bug 1 produced.
      expect(rootItem.name, 'Hogar');
      expect(rootItem.amountMinor, 15000);
      expect(rootItem.subcategories.single.name, 'Mercado');
    });
  });
}
