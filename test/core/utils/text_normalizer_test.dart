import 'package:billetudo/core/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForSearch', () {
    test('strips lowercase and uppercase Spanish diacritics', () {
      expect(normalizeForSearch('Préstamos'), 'prestamos');
      expect(normalizeForSearch('ÑOÑO'), 'nono');
      expect(normalizeForSearch('Educación'), 'educacion');
    });

    test('lowercases plain text without diacritics', () {
      expect(normalizeForSearch('Salud'), 'salud');
    });

    test('lets an unaccented query match an accented name', () {
      final query = normalizeForSearch('prestamos');
      final categoryName = normalizeForSearch('Préstamos');
      expect(categoryName.contains(query), isTrue);
    });

    test('leaves empty string unchanged', () {
      expect(normalizeForSearch(''), '');
    });
  });
}
