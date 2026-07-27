import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const money = MoneyFormatter();

  group('MoneyFormatter.formatSymbolEntry (item 20 — pending decimal)', () {
    test('whole-number entry (-1) reads like formatSymbol', () {
      expect(
        money.formatSymbolEntry(
          4500000,
          currencyCode: 'COP',
          entryFractionDigits: -1,
        ),
        money.formatSymbol(4500000, currencyCode: 'COP'),
      );
    });

    test('decimal just pressed (0) appends the pending separator for COP', () {
      // 45,00 stored as 4500 minor; COP shows it whole, so the comma is what
      // signals the decimal key landed.
      expect(
        money.formatSymbolEntry(
          4500,
          currencyCode: 'COP',
          entryFractionDigits: 0,
        ),
        '\$45,',
      );
    });

    test('a fraction digit after the comma shows it (…,X)', () {
      // 45,05 → 4505 minor, two fraction digits typed.
      expect(
        money.formatSymbolEntry(
          4505,
          currencyCode: 'COP',
          entryFractionDigits: 2,
        ),
        '\$45,05',
      );
      // A single typed zero after the comma stays visible during entry.
      expect(
        money.formatSymbolEntry(
          4500,
          currencyCode: 'COP',
          entryFractionDigits: 1,
        ),
        '\$45,0',
      );
    });

    test('does not double the separator when the value already shows one', () {
      // USD always renders its two decimals, so the string already has a comma;
      // the pending flag must not add a second one.
      final base = money.formatSymbol(4500, currencyCode: 'USD');
      expect(base.contains(','), isTrue);
      expect(
        money.formatSymbolEntry(
          4500,
          currencyCode: 'USD',
          entryFractionDigits: 0,
        ),
        base,
      );
    });
  });
}
