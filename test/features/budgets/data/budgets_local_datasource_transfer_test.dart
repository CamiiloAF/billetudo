import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// B-3 — transferencia presupuestable
/// (`docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §3) plus
/// budget-income-counts-in-budget, raw datasource level: `watchExpenses()`
/// must fold a `type = transfer` OR `type = income` transaction into its
/// results only when `countsInBudget = true`. A budgetable transfer produces
/// **two** rows: the origin-side row (`accountId` = the transfer's origin,
/// `isIncome = false`, unchanged behaviour) and a destination-side row
/// (`accountId` = the transfer's destination, `isIncome = true`, `id`
/// suffixed `-dest` so it never collides with the origin row's `id`). An
/// income has no other account to pick, so it stays a single row marked
/// `isIncome = true`. Scope matching against a budget's `BudgetAccounts` is a
/// layer above (`BudgetRepositoryImpl`/`BudgetProgressCalculator`), covered by
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
    final originRow = rows.firstWhere((r) => r.accountId == origin.id);

    expect(originRow.amountMinor, 25000);
    expect(originRow.isIncome, isFalse);
  });

  test(
      'type=transfer con countsInBudget=true tambien produce una fila '
      'DESTINO con isIncome=true, mismo monto/categoria/fecha, e id '
      'distinto de la fila origen', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final inserted = await database.into(database.transactions).insertReturning(
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

    expect(rows, hasLength(2));
    final originRow = rows.firstWhere((r) => r.accountId == origin.id);
    final destRow = rows.firstWhere((r) => r.accountId == destination.id);

    expect(originRow.id, inserted.id);
    expect(originRow.isIncome, isFalse);

    expect(destRow.id, isNot(originRow.id));
    expect(destRow.isIncome, isTrue);
    expect(destRow.amountMinor, 25000);
    expect(destRow.currency, 'COP');
    expect(destRow.date, DateTime(2026, 7, 1));
    expect(destRow.categoryId, originRow.categoryId);
  });

  test(
      'type=transfer con countsInBudget=false NO aparece (ni origen ni '
      'destino)', () async {
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

  test('un income presupuestable borrado (deletedAt) no aparece aunque cuente',
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
