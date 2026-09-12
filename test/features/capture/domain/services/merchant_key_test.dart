import 'package:billetudo/features/capture/domain/services/merchant_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('merchantKeyFor', () {
    test('upper-cases, strips accents and collapses whitespace', () {
      expect(merchantKeyFor('  Éxito   Calle 80 '), 'EXITO CALLE 80');
    });

    test('maps the spellings of one merchant to a single key', () {
      expect(
        merchantKeyFor('Éxito Calle 80'),
        merchantKeyFor('EXITO  CALLE  80'),
      );
    });

    test('keeps distinct merchants distinct', () {
      expect(merchantKeyFor('EXITO'), isNot(merchantKeyFor('EXITO EXPRESS')));
    });

    test('returns null when there is nothing to learn against', () {
      expect(merchantKeyFor(null), isNull);
      expect(merchantKeyFor('   '), isNull);
    });
  });
}
