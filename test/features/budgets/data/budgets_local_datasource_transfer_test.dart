import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// B-3 — transferencia presupuestable
/// (`docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §3) plus
/// budget-income-counts-in-budget, raw datasource level: `watchExpenses()`
/// must fold a `type = transfer` OR `type = income` transaction into its
/// results only when `countsInBudget = true`, as an origin-side row
/// (`accountId` = the transfer's origin, not destination — an income has no
/// other account to pick), and must mark an income row `isIncome = true`.
/// Scope matching against a budget's `BudgetAccounts` is a layer above
/// (`BudgetRepositoryImpl`/`BudgetProgressCalculator`), covered by
/// `budget_repository_impl_transfer_test.dart`.
void main() {
  late AppDatabase database;
  late BudgetsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = BudgetsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  Future<Account> createAccount(String name) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
            ),
          );

  test('type=expense siempre aparece', () async {
    final account = await createAccount('Efectivo');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 1),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, hasLength(1));
    expect(rows.single.accountId, account.id);
  });

  test(
      'type=transfer con countsInBudget=true aparece como gasto con la '
      'cuenta ORIGEN, no la destino', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: origin.id,
            transferAccountId: Value(destination.id),
            amountMinor: 25000,
            currency: 'COP',
            type: EntryType.transfer,
            date: DateTime(2026, 7, 1),
            countsInBudget: const Value(true),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, hasLength(1));
    expect(rows.single.accountId, origin.id);
    expect(rows.single.amountMinor, 25000);
  });

  test('type=transfer con countsInBudget=false NO aparece', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: origin.id,
            transferAccountId: Value(destination.id),
            amountMinor: 25000,
            currency: 'COP',
            type: EntryType.transfer,
            date: DateTime(2026, 7, 1),
            countsInBudget: const Value(false),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, isEmpty);
  });

  test('type=income con countsInBudget=false (default) no aparece', () async {
    final account = await createAccount('Efectivo');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.income,
            date: DateTime(2026, 7, 1),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, isEmpty);
  });

  test(
      'budget-income-counts-in-budget: type=income con countsInBudget=true '
      'aparece marcado isIncome=true', () async {
    final account = await createAccount('Efectivo');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.income,
            date: DateTime(2026, 7, 1),
            countsInBudget: const Value(true),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, hasLength(1));
    expect(rows.single.accountId, account.id);
    expect(rows.single.isIncome, isTrue);
  });

  test('una fila type=expense trae isIncome=false', () async {
    final account = await createAccount('Efectivo');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 1),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows.single.isIncome, isFalse);
  });

  test(
      'un income presupuestable borrado (deletedAt) no aparece aunque cuente',
      () async {
    final account = await createAccount('Efectivo');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.income,
            date: DateTime(2026, 7, 1),
            countsInBudget: const Value(true),
            deletedAt: Value(DateTime(2026, 7, 2)),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, isEmpty);
  });

  test('una transferencia borrada (deletedAt) no aparece aunque cuente',
      () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            accountId: origin.id,
            transferAccountId: Value(destination.id),
            amountMinor: 25000,
            currency: 'COP',
            type: EntryType.transfer,
            date: DateTime(2026, 7, 1),
            countsInBudget: const Value(true),
            deletedAt: Value(DateTime(2026, 7, 2)),
            updatedAt: const Value(0),
          ),
        );

    final rows = await datasource.watchExpenses().first;

    expect(rows, isEmpty);
  });
}
