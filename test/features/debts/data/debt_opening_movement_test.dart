import 'package:billetudo/core/database/app_database.dart' hide DebtDirection;
import 'package:billetudo/features/debts/data/datasources/debts_local_datasource.dart';
import 'package:billetudo/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    show TransactionType;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Data-layer coverage of the registro-inicial model (item 2 / 2b).
///
/// The load-bearing invariant: a debt of $X with an opening movement derives to
/// exactly $X (never $2X), backed by a single `Transaction` that moved the
/// chosen account. `principalMinor` is 0 in that case, so the opening figure is
/// counted once — from the movement, not twice.
void main() {
  late AppDatabase db;
  late DebtsLocalDatasource local;
  late DebtRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = DebtsLocalDatasource(db);
    repository = DebtRepositoryImpl(local, const DebtBalanceCalculator());
  });

  tearDown(() => db.close());

  Future<Account> createAccount() =>
      db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );

  DebtDraft draft({
    int principalMinor = 4200000,
    DebtDirection direction = DebtDirection.iOwe,
    DateTime? startDate,
    String? id,
  }) =>
      DebtDraft(
        id: id,
        name: 'Crédito carro',
        direction: direction,
        principalMinor: principalMinor,
        currency: 'COP',
        startDate: startDate,
      );

  Future<List<Transaction>> debtTransactions(String debtId) =>
      (db.select(db.transactions)..where((t) => t.debtId.equals(debtId))).get();

  test(
    'crear con registro: saldo derivado = \$X (no 2X), UNA tx, cuenta movida',
    () async {
      final account = await createAccount();

      final result = await repository.createDebtWithOpeningMovement(
        draft: draft(principalMinor: 4200000),
        accountId: account.id,
        date: DateTime(2026, 3, 1),
      );

      final debt = result.getOrElse((_) => throw StateError('expected debt'));
      expect(debt.principalMinor, 0, reason: 'principal stays 0');
      expect(debt.initialTransactionId, isNotNull);

      final txs = await debtTransactions(debt.id);
      expect(txs, hasLength(1), reason: 'exactly one opening movement');
      expect(txs.single.id, debt.initialTransactionId);
      expect(txs.single.amountMinor, 4200000);
      expect(txs.single.accountId, account.id);
      // "Yo debo" opening is an income (took the loan).
      expect(txs.single.type, EntryType.income);

      final balance = await repository.getBalance(debt.id);
      expect(
        balance.getOrElse((_) => throw StateError('balance')).outstandingMinor,
        4200000,
        reason: 'derived once, not doubled',
      );
    },
  );

  test('crear sin registro: principal = apertura, sin tx', () async {
    final result = await repository.createDebt(draft(principalMinor: 4200000));
    final debt = result.getOrElse((_) => throw StateError('expected debt'));

    expect(debt.principalMinor, 4200000);
    expect(debt.initialTransactionId, isNull);
    expect(await debtTransactions(debt.id), isEmpty);

    final balance = await repository.getBalance(debt.id);
    expect(
      balance.getOrElse((_) => throw StateError('balance')).outstandingMinor,
      4200000,
    );
  });

  test('update inicial: cambia monto y tipo cuando cambia la dirección',
      () async {
    final account = await createAccount();
    final created = await repository.createDebtWithOpeningMovement(
      draft: draft(principalMinor: 4200000),
      accountId: account.id,
      date: DateTime(2026, 3, 1),
    );
    final debt = created.getOrElse((_) => throw StateError('debt'));
    final txId = debt.initialTransactionId!;

    // Direction flipped to owedToMe → the opening disbursement becomes an
    // expense (lent the money), and the amount grows.
    final result = await repository.updateInitialMovementAmount(
      transactionId: txId,
      amountMinor: 5000000,
      type: TransactionType.expense,
    );
    expect(result.isRight(), isTrue);

    final tx = await (db.select(db.transactions)
          ..where((t) => t.id.equals(txId)))
        .getSingle();
    expect(tx.amountMinor, 5000000);
    expect(tx.type, EntryType.expense);
  });

  test('crear sin registro estampa el startDate del draft', () async {
    final start = DateTime(2025, 12, 1);
    final result = await repository.createDebt(draft(startDate: start));
    final debt = result.getOrElse((_) => throw StateError('debt'));

    expect(debt.startDate, start);
    final row =
        await (db.select(db.debts)..where((d) => d.id.equals(debt.id))).getSingle();
    expect(row.startDate, start);
  });

  test('crear con registro estampa el startDate del draft', () async {
    final account = await createAccount();
    final start = DateTime(2025, 12, 1);
    final result = await repository.createDebtWithOpeningMovement(
      draft: draft(startDate: start),
      accountId: account.id,
      date: start,
    );
    final debt = result.getOrElse((_) => throw StateError('debt'));

    expect(debt.startDate, start);
    // The opening movement is dated at the start date passed by the cubit.
    final txs = await debtTransactions(debt.id);
    expect(txs.single.date, start);
  });

  test('editar persiste el nuevo startDate', () async {
    final created = await repository.createDebt(
      draft(startDate: DateTime(2026, 1, 1)),
    );
    final debt = created.getOrElse((_) => throw StateError('debt'));

    final newStart = DateTime(2025, 6, 15);
    final result = await repository.updateDebt(
      draft(id: debt.id, startDate: newStart),
    );
    final updated = result.getOrElse((_) => throw StateError('updated'));

    expect(updated.startDate, newStart);
    final row =
        await (db.select(db.debts)..where((d) => d.id.equals(debt.id))).getSingle();
    expect(row.startDate, newStart);
  });

  test(
    'update inicial con date re-sincroniza la fecha del movimiento (sin tocar '
    'monto ni tipo)',
    () async {
      final account = await createAccount();
      final created = await repository.createDebtWithOpeningMovement(
        draft: draft(principalMinor: 4200000, startDate: DateTime(2026, 1, 1)),
        accountId: account.id,
        date: DateTime(2026, 1, 1),
      );
      final debt = created.getOrElse((_) => throw StateError('debt'));
      final txId = debt.initialTransactionId!;

      // Start-date-only edit: same amount, same (derived) type, new date.
      final newDate = DateTime(2026, 3, 15);
      final result = await repository.updateInitialMovementAmount(
        transactionId: txId,
        amountMinor: 4200000,
        type: TransactionType.income,
        date: newDate,
      );
      expect(result.isRight(), isTrue);

      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      expect(tx.date, newDate);
      expect(tx.amountMinor, 4200000);
      expect(tx.type, EntryType.income);
    },
  );

  test(
    'editar startDate + re-sync deja el piso de abonos y la fecha del registro '
    'coherentes',
    () async {
      final account = await createAccount();
      final created = await repository.createDebtWithOpeningMovement(
        draft: draft(principalMinor: 4200000, startDate: DateTime(2026, 1, 1)),
        accountId: account.id,
        date: DateTime(2026, 1, 1),
      );
      final debt = created.getOrElse((_) => throw StateError('debt'));
      final txId = debt.initialTransactionId!;

      final newStart = DateTime(2025, 6, 15);
      // The debt row keeps its startDate (persisted via updateDebt) …
      await repository.updateDebt(draft(id: debt.id, startDate: newStart));
      // … and the linked movement is re-synced to the same date.
      await repository.updateInitialMovementAmount(
        transactionId: txId,
        amountMinor: 4200000,
        type: TransactionType.income,
        date: newStart,
      );

      final updatedDebt =
          await repository.getDebt(debt.id).then((r) => r.getOrElse((_) {
                throw StateError('debt');
              }));
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      // The backdate floor (debt.effectiveStartDate) and the registro's date
      // are the same day.
      expect(updatedDebt.effectiveStartDate, newStart);
      expect(tx.date, newStart);
    },
  );

  test('crear con registro "Me deben": el desembolso es un gasto', () async {
    final account = await createAccount();
    final result = await repository.createDebtWithOpeningMovement(
      draft: draft(principalMinor: 1000000, direction: DebtDirection.owedToMe),
      accountId: account.id,
      date: DateTime(2026, 3, 1),
    );
    final debt = result.getOrElse((_) => throw StateError('debt'));
    final txs = await debtTransactions(debt.id);
    expect(txs.single.type, EntryType.expense);

    final balance = await repository.getBalance(debt.id);
    expect(
      balance.getOrElse((_) => throw StateError('b')).outstandingMinor,
      1000000,
    );
  });
}
