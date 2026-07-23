import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/features/debts/data/datasources/debts_local_datasource.dart';
import 'package:billetudo/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart' as domain;
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';

/// Reproduces the confirmed on-device bug against a **real PowerSync-backed**
/// [AppDatabase] (the production connection, `driftConnection(powerSyncDb)`),
/// not a bare `NativeDatabase`. The tables are PowerSync-managed views, exactly
/// like production; a plain in-memory Drift database does NOT reproduce this.
///
/// A single LIVE `watchDebtDetail` subscription is primed, then a write lands
/// while it stays subscribed (the modal-abono-sheet situation): it must
/// re-emit with the reduced balance, the same way it does for a `DebtEntry`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase database;
  late DebtRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('billetudo_debt_reactivity');
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    database = AppDatabase(driftConnection(powerSync));
    repository = DebtRepositoryImpl(
      DebtsLocalDatasource(database),
      const DebtBalanceCalculator(),
    );
  });

  tearDown(() async {
    await database.close();
    await powerSync.close();
    await tempDir.delete(recursive: true);
  });

  Future<Debt> createDebt() => database.into(database.debts).insertReturning(
        DebtsCompanion.insert(
          name: 'Crédito carro',
          direction: DebtDirection.iOwe,
          principalMinor: 100000,
          currency: 'COP',
          accrualMode: const Value(DebtAccrualMode.manual),
        ),
      );

  Future<Account> createAccount() =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Efectivo',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );

  /// Subscribes to a single live detail stream and records every outstanding
  /// balance it reports, so a test can assert the sequence of live emissions.
  ({List<int> seen, Future<void> Function() cancel}) liveOutstanding(
    String debtId,
  ) {
    final seen = <int>[];
    final sub = repository.watchDebtDetail(debtId).listen(
          (result) => result.fold(
            (_) {},
            (detail) => seen.add(detail.balance.outstandingMinor),
          ),
        );
    return (seen: seen, cancel: sub.cancel);
  }

  Future<void> pumpUntil(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('cash abono (Transaction with debtId) re-emits the live detail',
      () async {
    final debt = await createDebt();
    final account = await createAccount();
    final live = liveOutstanding(debt.id);
    addTearDown(live.cancel);

    await pumpUntil(() => live.seen.contains(100000));
    expect(live.seen, contains(100000), reason: 'primed at opening balance');

    await repository.registerCashEvent(
      debtId: debt.id,
      accountId: account.id,
      amountMinor: 40000,
      type: TransactionType.expense,
      currency: 'COP',
      date: DateTime.now(),
    );

    await pumpUntil(() => live.seen.contains(60000));
    expect(
      live.seen,
      contains(60000),
      reason: 'the live detail must re-emit the reduced balance after a '
          'cash abono (Transaction) lands while it stays subscribed',
    );
  });

  test('ledger abono (DebtEntry) re-emits the live detail', () async {
    final debt = await createDebt();
    final live = liveOutstanding(debt.id);
    addTearDown(live.cancel);

    await pumpUntil(() => live.seen.contains(100000));
    expect(live.seen, contains(100000), reason: 'primed at opening balance');

    await repository.addDebtEntry(
      DebtEntryDraft(
        debtId: debt.id,
        kind: domain.DebtEntryKind.payment,
        amountMinor: -40000,
        entryDate: DateTime.now(),
      ),
    );

    await pumpUntil(() => live.seen.contains(60000));
    expect(live.seen, contains(60000));
  });
}
