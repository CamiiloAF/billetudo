import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../home_fixtures.dart';

void main() {
  final month = DateTime(2026, 7);
  const active = {'acc-1', 'acc-2'};

  MonthSpending build(List<dynamic> transactions) => MonthSpending.from(
        month: month,
        transactions: transactions.cast(),
        activeAccountIds: active,
        fallbackCurrency: 'COP',
      );

  test('suma solo los gastos, en centavos', () {
    final spending = build([
      buildActivity(amountMinor: 82000),
      buildActivity(
        id: 'tx-2',
        amountMinor: 44900,
      ),
    ]);

    expect(spending.displayTotalMinor, 126900);
    expect(spending.displayCurrency, 'COP');
    expect(spending.hasExpenses, isTrue);
  });

  test('excluye ingresos', () {
    final spending = build([
      buildActivity(amountMinor: 82000),
      buildActivity(
        id: 'tx-2',
        amountMinor: 2100000,
        type: TransactionType.income,
      ),
    ]);

    expect(spending.displayTotalMinor, 82000);
  });

  test('excluye transferencias (HU-03)', () {
    final spending = build([
      buildActivity(amountMinor: 50000),
      buildActivity(
        id: 'tx-2',
        amountMinor: 999999,
        type: TransactionType.transfer,
      ),
    ]);

    expect(spending.displayTotalMinor, 50000);
  });

  test('excluye movimientos ligados a deuda (debtId)', () {
    final spending = build([
      buildActivity(amountMinor: 50000),
      buildActivity(
        id: 'tx-2',
        amountMinor: 30000,
        debtId: 'debt-1',
      ),
    ]);

    expect(spending.displayTotalMinor, 50000);
  });

  test('excluye gastos de cuentas no activas (con lápida)', () {
    final spending = build([
      buildActivity(amountMinor: 50000),
      buildActivity(
        id: 'tx-2',
        accountId: 'acc-tombstoned',
        amountMinor: 70000,
      ),
    ]);

    expect(spending.displayTotalMinor, 50000);
  });

  test('sin gastos: total 0 y usa la moneda de respaldo', () {
    final spending = MonthSpending.from(
      month: month,
      transactions: const [],
      activeAccountIds: active,
      fallbackCurrency: 'USD',
    );

    expect(spending.hasExpenses, isFalse);
    expect(spending.displayTotalMinor, 0);
    expect(spending.displayCurrency, 'USD');
  });

  test('varias monedas: el hero muestra la de mayor total', () {
    final spending = build([
      buildActivity(amountMinor: 50000),
      buildActivity(id: 'tx-2', amountMinor: 90000, currency: 'USD'),
    ]);

    expect(spending.subtotals, hasLength(2));
    expect(spending.displayCurrency, 'USD');
    expect(spending.displayTotalMinor, 90000);
  });

  test('subtotales ordenados por código de moneda (emisión estable)', () {
    final spending = build([
      buildActivity(currency: 'USD'),
      buildActivity(id: 'tx-2'),
      buildActivity(id: 'tx-3', currency: 'EUR'),
    ]);

    expect(
      spending.subtotals.map((s) => s.currency).toList(),
      ['COP', 'EUR', 'USD'],
    );
  });

  test('empate de totales: desempata determinista por el código ya ordenado',
      () {
    final spending = build([
      buildActivity(amountMinor: 40000, currency: 'USD'),
      buildActivity(id: 'tx-2', amountMinor: 40000),
    ]);

    // Both total 40000; the sorted-first code (COP) wins, deterministically.
    expect(spending.displayCurrency, 'COP');
    expect(spending.displayTotalMinor, 40000);
  });

  test('la moneda de respaldo se ignora cuando sí hay gastos', () {
    final spending = MonthSpending.from(
      month: month,
      transactions: [buildActivity(amountMinor: 12345)].cast(),
      activeAccountIds: active,
      fallbackCurrency: 'EUR',
    );

    // COP has the only expense, so it leads regardless of the EUR fallback.
    expect(spending.displayCurrency, 'COP');
    expect(spending.displayTotalMinor, 12345);
  });

  test('el mes se normaliza al primer día del mes', () {
    final spending = MonthSpending.from(
      month: DateTime(2026, 7, 23, 14, 5),
      transactions: const [],
      activeAccountIds: active,
      fallbackCurrency: 'COP',
    );

    expect(spending.month, DateTime(2026, 7));
  });
}
