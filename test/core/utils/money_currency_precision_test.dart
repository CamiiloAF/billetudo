import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Switching currency re-cuts a figure's precision without ever converting it:
/// the minor unit stored is 1/100 for every currency, so `450000000` means
/// 4.500.000,00 in COP and in USD alike. Only how many decimals are *shown*
/// changes, and the stored amount is rounded to match so a field can never
/// display a figure the state does not hold.
void main() {
  const money = MoneyFormatter();

  group('roundToCurrencyPrecision', () {
    test('leaves an amount untouched when the currency keeps its cents', () {
      expect(MoneyFormatter.roundToCurrencyPrecision(123456, 'USD'), 123456);
    });

    test('rounds half-up to whole units for a currency without cents', () {
      expect(MoneyFormatter.roundToCurrencyPrecision(123456, 'COP'), 123500);
      expect(MoneyFormatter.roundToCurrencyPrecision(123450, 'COP'), 123500);
      expect(MoneyFormatter.roundToCurrencyPrecision(123449, 'COP'), 123400);
    });

    test('rounds away from zero on a negative amount', () {
      expect(MoneyFormatter.roundToCurrencyPrecision(-123456, 'COP'), -123500);
    });

    test('a whole COP amount is already at its precision', () {
      expect(
        MoneyFormatter.roundToCurrencyPrecision(450000000, 'COP'),
        450000000,
      );
    });
  });

  group('reformatForCurrency', () {
    test('COP to USD gains the decimals without changing the figure', () {
      expect(money.reformatForCurrency('4.500.000', 'USD'), '4.500.000,00');
    });

    test('USD to COP drops the cents into the rounded whole unit', () {
      expect(money.reformatForCurrency('1.234,56', 'COP'), '1.235');
    });

    test('USD to COP keeps a negative sign', () {
      expect(money.reformatForCurrency('-1.234,56', 'COP'), '-1.235');
    });

    test('an empty field stays empty instead of becoming a zero', () {
      expect(money.reformatForCurrency('', 'COP'), '');
    });

    test('a half-typed figure is handed back untouched', () {
      expect(money.reformatForCurrency('-', 'COP'), '-');
      expect(money.reformatForCurrency(',', 'USD'), ',');
    });

    test('the result round-trips through the parser it came from', () {
      final text = money.reformatForCurrency('1.234,56', 'COP');
      expect(MoneyFormatter.parseMinor(text), 123500);
    });
  });

  group('item 4: entrada vs display de decimales en COP', () {
    test('inputDecimals permite teclear centavos en toda moneda, COP incluido',
        () {
      expect(MoneyFormatter.inputDecimals('COP'), 2);
      expect(MoneyFormatter.inputDecimals('USD'), 2);
    });

    test('displayDecimals: COP entero no muestra decimales, con centavos si',
        () {
      expect(MoneyFormatter.displayDecimals(45000, 'COP'), 0); // $450 exacto
      expect(MoneyFormatter.displayDecimals(4550, 'COP'), 2); // $45,50
      expect(MoneyFormatter.displayDecimals(-4550, 'COP'), 2); // negativo
      expect(MoneyFormatter.displayDecimals(0, 'COP'), 0);
    });

    test('displayDecimals: USD siempre muestra sus dos decimales', () {
      expect(MoneyFormatter.displayDecimals(1200, 'USD'), 2);
      expect(MoneyFormatter.displayDecimals(1234, 'USD'), 2);
    });

    test('formatSymbol: COP entero se ve como antes (sin ",00")', () {
      expect(money.formatSymbol(123400, currencyCode: 'COP'), r'$1.234');
    });

    test('formatSymbol: COP con centavos revela los decimales', () {
      expect(money.formatSymbol(123450, currencyCode: 'COP'), r'$1.234,50');
    });

    test('format: COP entero sin coma decimal; con centavos la incluye', () {
      // Se evita fijar el codigo/espacio no-separable de intl; basta con que
      // el entero no lleve parte decimal y el monto con centavos si.
      expect(money.format(45000, currencyCode: 'COP'), isNot(contains(',')));
      expect(money.format(45050, currencyCode: 'COP'), contains(',50'));
    });
  });
}
