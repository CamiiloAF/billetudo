import 'package:billetudo/features/capture/domain/parsing/notification_amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationAmountParser', () {
    // The three real shapes seen in the wild, one per issuer. The 1000x
    // mistake lives here: `128.920,00` is one hundred twenty-eight THOUSAND
    // pesos.
    const Map<String, int> realFormats = <String, int>{
      r'$58.470,00': 5847000, // Nu, purchase
      '128.920,00': 12892000, // Nu, income, no currency symbol at all
      r'$1': 100, // Nequi, no decimals
      r'$1,00': 100, // Nu, one peso with decimals
      '38.000,00 COP': 3800000, // Google Wallet, currency after the figure
      r'$5.500,00': 550000,
      r'$115.250,00': 11525000,
      '24.800,00 COP': 2480000,
    };

    realFormats.forEach((String raw, int expected) {
      test('parses $raw as $expected cents', () {
        expect(NotificationAmountParser.parseMinor(raw), expected);
      });
    });

    test('treats a lone dot before three digits as a thousands separator', () {
      expect(NotificationAmountParser.parseMinor(r'$45.900'), 4590000);
    });

    test('treats a lone comma before three digits as a thousands separator',
        () {
      expect(NotificationAmountParser.parseMinor(r'$45,900'), 4590000);
    });

    test('treats a lone separator before two digits as decimals', () {
      expect(NotificationAmountParser.parseMinor(r'$45,90'), 4590);
      expect(NotificationAmountParser.parseMinor(r'$45.90'), 4590);
    });

    test('handles millions with both separators', () {
      expect(NotificationAmountParser.parseMinor(r'$1.234.567,50'), 123456750);
    });

    test('drops the trailing punctuation of the sentence', () {
      expect(NotificationAmountParser.parseMinor(r'$1.'), 100);
      expect(NotificationAmountParser.parseMinor('1.234,'), 123400);
    });

    test('returns null when there is no usable figure', () {
      expect(NotificationAmountParser.parseMinor(''), isNull);
      expect(NotificationAmountParser.parseMinor('COP'), isNull);
      expect(NotificationAmountParser.parseMinor(r'$0'), isNull);
      expect(NotificationAmountParser.parseMinor(r'$0,00'), isNull);
    });

    test('rejects an absurd figure instead of overflowing', () {
      expect(NotificationAmountParser.parseMinor('999999999999'), isNull);
    });
  });
}
