import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountsLocalDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = AccountsLocalDatasource(db);
  });

  tearDown(() async => db.close());

  Future<String> insertAccount({
    String name = 'Cuenta',
    DateTime? tombstonedAt,
  }) =>
      db
          .into(db.accounts)
          .insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
              tombstonedAt: Value(tombstonedAt),
            ),
          )
          .then((row) => row.id);

  Future<String> insertBudget({
    String name = 'Presupuesto',
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      db
          .into(db.budgets)
          .insertReturning(
            BudgetsCompanion.insert(
              name: name,
              amountMinor: 100000,
              currency: 'COP',
              period: BudgetPeriod.monthly,
              startDate: DateTime(2026, 1, 1),
              archivedAt: Value(archivedAt),
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
            ),
          )
          .then((row) => row.id);

  Future<void> insertBudgetAccount(
    String budgetId,
    String accountId, {
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      db.into(db.budgetAccounts).insert(
            BudgetAccountsCompanion.insert(
              budgetId: budgetId,
              accountId: accountId,
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
            ),
          );

  group('countReferencingBudgets', () {
    test('0 when no budget references the account', () async {
      final accountId = await insertAccount();

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('counts an active budget whose scope references the account',
        () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget();
      await insertBudgetAccount(budgetId, accountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 1);
    });

    test('does NOT count a closed (archived) budget', () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget(archivedAt: DateTime(2026, 7, 15));
      await insertBudgetAccount(budgetId, accountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('does NOT count a soft-deleted budget', () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget(deletedAt: DateTime(2026, 7, 15));
      await insertBudgetAccount(budgetId, accountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('does NOT count a tombstoned budget', () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget(tombstonedAt: DateTime(2026, 7, 15));
      await insertBudgetAccount(budgetId, accountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('does NOT count a soft-deleted scope row even on an active budget',
        () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget();
      await insertBudgetAccount(
        budgetId,
        accountId,
        deletedAt: DateTime(2026, 7, 15),
      );

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('does NOT count a tombstoned scope row even on an active budget',
        () async {
      final accountId = await insertAccount();
      final budgetId = await insertBudget();
      await insertBudgetAccount(
        budgetId,
        accountId,
        tombstonedAt: DateTime(2026, 7, 15),
      );

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });

    test('sums every active budget scoping the account', () async {
      final accountId = await insertAccount();
      final budget1 = await insertBudget(name: 'Uno');
      final budget2 = await insertBudget(name: 'Dos');
      await insertBudgetAccount(budget1, accountId);
      await insertBudgetAccount(budget2, accountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 2);
    });

    test('ignores budgets scoping a different account', () async {
      final accountId = await insertAccount();
      final otherAccountId = await insertAccount(name: 'Otra');
      final budgetId = await insertBudget();
      await insertBudgetAccount(budgetId, otherAccountId);

      final count = await datasource.countReferencingBudgets(accountId);

      expect(count, 0);
    });
  });
}
