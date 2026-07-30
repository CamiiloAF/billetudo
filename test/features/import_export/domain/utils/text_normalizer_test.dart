import 'package:billetudo/features/import_export/domain/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForMatching', () {
    test('ignora mayúsculas', () {
      expect(normalizeForMatching('Comida y Bebida'), 'comida y bebida');
    });

    test('ignora tildes', () {
      expect(normalizeForMatching('Educación'), 'educacion');
    });

    test('colapsa espacios repetidos y recorta bordes', () {
      expect(normalizeForMatching('  comida   y  bebida  '), 'comida y bebida');
    });

    test('"comida y bebida" coincide con "Comida y Bebida" (HU-06)', () {
      expect(
        normalizeForMatching('comida y bebida'),
        normalizeForMatching('Comida y Bebida'),
      );
    });

    test('ñ se normaliza a n', () {
      expect(normalizeForMatching('Ño'), 'no');
    });
  });
}
