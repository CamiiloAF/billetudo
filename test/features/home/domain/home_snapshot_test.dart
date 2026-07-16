import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../home_fixtures.dart';

void main() {
  final month = DateTime(2026, 7);

  test('el feed reciente incluye income, expense y transfer (actividad literal)',
      () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount()],
      transactions: [
        buildActivity(id: 'a'),
        buildActivity(id: 'b', type: TransactionType.income),
        buildActivity(id: 'c', type: TransactionType.transfer),
      ],
    );

    expect(snapshot.recentActivity, hasLength(3));
    // ...pero el gasto del hero sí excluye transfer.
    expect(snapshot.spending.displayTotalMinor, 10000);
  });

  test('el feed excluye movimientos de cuentas no activas (HU-05)', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount()],
      transactions: [
        buildActivity(id: 'a'),
        buildActivity(id: 'b', accountId: 'acc-tombstoned'),
      ],
    );

    expect(snapshot.recentActivity.map((e) => e.transaction.id), ['a']);
  });

  test('ordena por fecha descendente y limita a 5', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount()],
      transactions: [
        for (var day = 1; day <= 8; day++)
          buildActivity(id: 'tx-$day', date: DateTime(2026, 7, day)),
      ],
    );

    expect(snapshot.recentActivity, hasLength(HomeSnapshot.recentActivityLimit));
    expect(snapshot.recentActivity.first.transaction.id, 'tx-8');
    expect(snapshot.recentActivity.last.transaction.id, 'tx-4');
  });

  test('sin movimientos: isEmpty (estado de bienvenida, HU-08)', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount()],
      transactions: const [],
    );

    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.spending.displayTotalMinor, 0);
  });

  test('solo transferencias: no está vacío (hay actividad) aunque el gasto sea 0',
      () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount()],
      transactions: [
        buildActivity(id: 'a', type: TransactionType.transfer),
      ],
    );

    expect(snapshot.isEmpty, isFalse);
    expect(snapshot.spending.hasExpenses, isFalse);
  });

  test('el feed agrega TODAS las cuentas activas, no solo la primera (HU-05)',
      () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [
        buildActiveAccount(id: 'acc-1'),
        buildActiveAccount(id: 'acc-2'),
        buildActiveAccount(id: 'acc-3'),
      ],
      transactions: [
        buildActivity(id: 'a', accountId: 'acc-1'),
        buildActivity(id: 'b', accountId: 'acc-2'),
        buildActivity(id: 'c', accountId: 'acc-3'),
        // A tx on an account that is not in the active set is dropped.
        buildActivity(id: 'd', accountId: 'acc-tombstoned'),
      ],
    );

    expect(
      snapshot.recentActivity.map((e) => e.transaction.id).toSet(),
      {'a', 'b', 'c'},
    );
  });

  test(
      'el gasto del hero suma solo las cuentas activas de varias cuentas '
      '(HU-03)', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [
        buildActiveAccount(id: 'acc-1'),
        buildActiveAccount(id: 'acc-2'),
      ],
      transactions: [
        buildActivity(id: 'a', accountId: 'acc-1', amountMinor: 30000),
        buildActivity(id: 'b', accountId: 'acc-2', amountMinor: 45000),
        buildActivity(id: 'c', accountId: 'acc-tombstoned', amountMinor: 99999),
      ],
    );

    // 30000 + 45000, never touching the tombstoned account's expense.
    expect(snapshot.spending.displayTotalMinor, 75000);
  });

  test('sin gastos: el hero \$0 usa la moneda de la primera cuenta activa', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount(id: 'acc-1', currency: 'USD')],
      transactions: const [],
    );

    expect(snapshot.spending.displayTotalMinor, 0);
    expect(snapshot.spending.displayCurrency, 'USD');
  });

  test('sin cuentas: el hero \$0 cae al fallbackCurrency por defecto (COP)', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: const [],
      transactions: const [],
    );

    expect(snapshot.recentActivity, isEmpty);
    expect(snapshot.spending.displayCurrency, 'COP');
  });

  test('multi-moneda: el hero muestra la moneda de mayor total (sin sumar '
      'cruzado)', () {
    final snapshot = HomeSnapshot.from(
      month: month,
      accounts: [buildActiveAccount(id: 'acc-1')],
      transactions: [
        buildActivity(id: 'a', amountMinor: 20000, currency: 'COP'),
        buildActivity(id: 'b', amountMinor: 500000, currency: 'USD'),
      ],
    );

    expect(snapshot.spending.subtotals, hasLength(2));
    expect(snapshot.spending.displayCurrency, 'USD');
    expect(snapshot.spending.displayTotalMinor, 500000);
  });
}
