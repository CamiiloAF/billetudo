import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account_fixtures.dart';

void main() {
  // La moneda es el sujeto de estas pruebas: se pide siempre explícita en vez
  // de heredar el default del fixture.
  AccountWithBalance accountIn(
    String currency, {
    required String id,
    required int balanceMinor,
    AccountType type = AccountType.bank,
  }) =>
      buildAccountWithBalance(
        account: buildAccount(id: id, currency: currency, type: type),
        balanceMinor: balanceMinor,
      );

  AccountWithBalance cardIn(
    String currency, {
    required String id,
    required int balanceMinor,
  }) =>
      buildAccountWithBalance(
        account:
            buildCard(id: id, currency: currency, creditLimitMinor: 900000),
        balanceMinor: balanceMinor,
      );

  group('AccountsOverview.from — moneda única', () {
    test('suma el patrimonio de todas las cuentas de la misma moneda', () {
      final overview = AccountsOverview.from([
        accountIn('COP', id: 'a', balanceMinor: 500000),
        accountIn('COP', id: 'b', balanceMinor: 250000),
      ]);

      expect(overview.isSingleCurrency, isTrue);
      expect(overview.subtotals.single.currency, 'COP');
      expect(overview.subtotals.single.netWorthMinor, 750000);
      expect(overview.singleCurrencySubtotal?.netWorthMinor, 750000);
    });

    test('la deuda de la tarjeta resta del patrimonio y se reporta aparte', () {
      final overview = AccountsOverview.from([
        accountIn('COP', id: 'a', balanceMinor: 500000),
        cardIn('COP', id: 'c', balanceMinor: -200000),
      ]);

      final subtotal = overview.subtotals.single;
      expect(subtotal.netWorthMinor, 300000); // 500000 - 200000
      expect(subtotal.debtMinor, 200000); // positiva, para la sub-línea
      expect(subtotal.hasDebt, isTrue);
    });

    test('un saldo negativo que no es tarjeta no cuenta como deuda', () {
      final overview = AccountsOverview.from([
        accountIn('COP', id: 'a', balanceMinor: -5000, type: AccountType.cash),
      ]);

      expect(overview.subtotals.single.netWorthMinor, -5000);
      expect(overview.subtotals.single.debtMinor, 0);
      expect(overview.subtotals.single.hasDebt, isFalse);
    });

    test('una tarjeta pagada (saldo 0) no reporta deuda', () {
      final overview = AccountsOverview.from([
        cardIn('COP', id: 'c', balanceMinor: 0),
      ]);

      expect(overview.subtotals.single.debtMinor, 0);
    });
  });

  group('AccountsOverview.from — multi-moneda', () {
    test('NUNCA suma monedas distintas: un subtotal por moneda', () {
      final overview = AccountsOverview.from([
        accountIn('COP', id: 'a', balanceMinor: 500000),
        accountIn('USD', id: 'b', balanceMinor: 12000),
        accountIn('COP', id: 'c', balanceMinor: 100000),
      ]);

      expect(overview.isSingleCurrency, isFalse);
      expect(overview.singleCurrencySubtotal, isNull);
      expect(overview.subtotals.map((s) => s.currency), ['COP', 'USD']);
      expect(overview.subtotals.first.netWorthMinor, 600000);
      expect(overview.subtotals.last.netWorthMinor, 12000);
      // 600000 + 12000 = 612000 sería un número inventado: no debe existir.
      expect(
        overview.subtotals.map((s) => s.netWorthMinor),
        isNot(contains(612000)),
      );
    });

    test('la deuda solo agrega tarjetas de la misma moneda', () {
      final overview = AccountsOverview.from([
        cardIn('COP', id: 'c1', balanceMinor: -300000),
        cardIn('USD', id: 'c2', balanceMinor: -4000),
        cardIn('COP', id: 'c3', balanceMinor: -100000),
      ]);

      final cop = overview.subtotals.firstWhere((s) => s.currency == 'COP');
      final usd = overview.subtotals.firstWhere((s) => s.currency == 'USD');
      expect(cop.debtMinor, 400000);
      expect(usd.debtMinor, 4000);
    });

    test('los subtotales salen ordenados por código de moneda', () {
      final overview = AccountsOverview.from([
        accountIn('USD', id: 'a', balanceMinor: 1),
        accountIn('COP', id: 'b', balanceMinor: 1),
        accountIn('EUR', id: 'c', balanceMinor: 1),
      ]);

      expect(overview.subtotals.map((s) => s.currency), ['COP', 'EUR', 'USD']);
    });
  });

  test('sin cuentas activas no hay subtotales', () {
    final overview = AccountsOverview.from(const []);

    expect(overview.isEmpty, isTrue);
    expect(overview.isSingleCurrency, isFalse);
    expect(overview.singleCurrencySubtotal, isNull);
  });
}
