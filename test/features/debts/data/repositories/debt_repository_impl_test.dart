import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/debts/data/datasources/debts_local_datasource.dart';
import 'package:billetudo/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    show TransactionType;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// budget-income-counts-in-budget, data-layer coverage of
/// [DebtRepositoryImpl.registerCashEvent] and
/// [DebtRepositoryImpl.linkTransactionToDebt] against a real in-memory Drift
/// db — the `countsInBudget` write those two methods make is the load-bearing
/// behaviour a mocked repository cannot exercise.
void main() {
  late AppDatabase db;
  late DebtsLocalDatasource local;
  late DebtRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = DebtsLocalDatasource(db);
    repository = DebtRepositoryImpl(
      local,
      const DebtBalanceCalculator(),
      const NoopCrashReporter(),
    );
  });

  tearDown(() => db.close());

  Future<Account> createAccount() => db.into(db.accounts).insertReturning(
        AccountsCompanion.insert(
          name: 'Efectivo',
          type: AccountType.cash,
          currency: 'COP',
        ),
      );

  Future<Debt> createDebt(DebtDirection direction) =>
      db.into(db.debts).insertReturning(
            DebtsCompanion.insert(
              name: 'Préstamo a Ana',
              direction: direction,
              principalMinor: 100000,
              currency: 'COP',
              updatedAt: const Value(0),
            ),
          );

  Future<Transaction> createTransaction({
    required String accountId,
    required EntryType type,
    int amountMinor = 10000,
  }) =>
      db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: amountMinor,
              currency: 'COP',
              type: type,
              date: DateTime(2026, 5, 1),
              updatedAt: const Value(0),
            ),
          );

  group('registerCashEvent', () {
    test(
        'criterion 1: persists countsInBudget = true when the caller '
        'resolved it (owedToMe + payment/repago recibido)', () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.owedToMe);

      await repository.registerCashEvent(
        debtId: debt.id,
        accountId: account.id,
        amountMinor: 10000,
        type: TransactionType.income,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        countsInBudget: true,
      );

      final rows =
          await (db.select(db.transactions)..where((t) => t.debtId.equals(debt.id)))
              .get();
      expect(rows, hasLength(1));
      expect(rows.single.countsInBudget, isTrue);
    });

    test(
        'criterion 2: persists countsInBudget = false for every other '
        'direction × kind default', () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.iOwe);

      await repository.registerCashEvent(
        debtId: debt.id,
        accountId: account.id,
        amountMinor: 20000,
        type: TransactionType.expense,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        countsInBudget: false,
      );

      final rows =
          await (db.select(db.transactions)..where((t) => t.debtId.equals(debt.id)))
              .get();
      expect(rows, hasLength(1));
      expect(rows.single.countsInBudget, isFalse);
    });
  });

  group('linkTransactionToDebt', () {
    test(
        'criterion 3: forces countsInBudget = true when linking an income '
        'transaction to an owedToMe debt (repago recibido after the fact)',
        () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.owedToMe);
      final transaction = await createTransaction(
        accountId: account.id,
        type: EntryType.income,
      );
      expect(transaction.countsInBudget, isFalse);

      final result = await repository.linkTransactionToDebt(
        transactionId: transaction.id,
        debtId: debt.id,
      );

      expect(result.isRight(), isTrue);
      final row =
          await (db.select(db.transactions)..where((t) => t.id.equals(transaction.id)))
              .getSingle();
      expect(row.debtId, debt.id);
      expect(row.countsInBudget, isTrue);
    });

    test(
        'linking an expense transaction to an iOwe debt leaves '
        'countsInBudget untouched (still false)', () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.iOwe);
      final transaction = await createTransaction(
        accountId: account.id,
        type: EntryType.expense,
      );

      await repository.linkTransactionToDebt(
        transactionId: transaction.id,
        debtId: debt.id,
      );

      final row =
          await (db.select(db.transactions)..where((t) => t.id.equals(transaction.id)))
              .getSingle();
      expect(row.debtId, debt.id);
      expect(row.countsInBudget, isFalse);
    });

    test(
        'linking an income transaction to an iOwe debt (the loan itself, not '
        'a repayment) leaves countsInBudget untouched', () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.iOwe);
      final transaction = await createTransaction(
        accountId: account.id,
        type: EntryType.income,
      );

      await repository.linkTransactionToDebt(
        transactionId: transaction.id,
        debtId: debt.id,
      );

      final row =
          await (db.select(db.transactions)..where((t) => t.id.equals(transaction.id)))
              .getSingle();
      expect(row.countsInBudget, isFalse);
    });

    test(
        'does not clobber a countsInBudget the user had already set to true '
        'for an unrelated reason, when the link itself would not force it',
        () async {
      final account = await createAccount();
      final debt = await createDebt(DebtDirection.iOwe);
      final transaction = await db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 10000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 5, 1),
              countsInBudget: const Value(true),
              updatedAt: const Value(0),
            ),
          );

      await repository.linkTransactionToDebt(
        transactionId: transaction.id,
        debtId: debt.id,
      );

      final row =
          await (db.select(db.transactions)..where((t) => t.id.equals(transaction.id)))
              .getSingle();
      expect(row.countsInBudget, isTrue);
    });

    test('rejects linking a transaction that does not exist', () async {
      final debt = await createDebt(DebtDirection.owedToMe);

      final result = await repository.linkTransactionToDebt(
        transactionId: 'missing',
        debtId: debt.id,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
