import 'package:billetudo/features/import_export/data/models/decimal_amount_parser.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecimalAmountParser.parse — convención de punto decimal', () {
    test('19.99 se convierte exacto en 1999 centavos (nunca 1998)', () {
      final parsed = DecimalAmountParser.parse(
        '19.99',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed, isNotNull);
      expect(parsed!.minorUnits, 1999);
      expect(parsed.rounded, isFalse);
    });

    test('acepta miles con coma como separador de agrupación', () {
      final parsed = DecimalAmountParser.parse(
        '1,234.56',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, 123456);
    });

    test('un monto negativo conserva el signo', () {
      final parsed = DecimalAmountParser.parse(
        '-19.99',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, -1999);
    });
  });

  group('DecimalAmountParser.parse — convención de coma decimal', () {
    test('acepta miles con punto y decimales con coma (es-CO)', () {
      final parsed = DecimalAmountParser.parse(
        '1.234,56',
        convention: DecimalConvention.comma,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, 123456);
    });

    test('un entero sin decimales se rellena a la precisión de la moneda',
        () {
      final parsed = DecimalAmountParser.parse(
        '45000',
        convention: DecimalConvention.comma,
        currencyDecimals: 0,
      );

      expect(parsed!.minorUnits, 45000);
    });
  });

  group('DecimalAmountParser.parse — redondeo (nunca se descarta la fila)',
      () {
    test('más decimales de los que admite la moneda: redondea half-up', () {
      final parsed = DecimalAmountParser.parse(
        '19.995',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, 2000); // 19.995 -> 20.00
      expect(parsed.rounded, isTrue);
    });

    test('decimales extra por debajo de .5 truncan hacia abajo', () {
      final parsed = DecimalAmountParser.parse(
        '19.994',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, 1999);
      expect(parsed.rounded, isTrue);
    });

    test('ceros extra no cuentan como redondeados', () {
      final parsed = DecimalAmountParser.parse(
        '19.9900',
        convention: DecimalConvention.dot,
        currencyDecimals: 2,
      );

      expect(parsed!.minorUnits, 1999);
      expect(parsed.rounded, isFalse);
    });
  });

  group('DecimalAmountParser.parse — valores inválidos', () {
    test('vacío no es un monto', () {
      expect(
        DecimalAmountParser.parse(
          '',
          convention: DecimalConvention.dot,
          currencyDecimals: 2,
        ),
        isNull,
      );
    });

    test('texto no numérico no es un monto', () {
      expect(
        DecimalAmountParser.parse(
          'abc',
          convention: DecimalConvention.dot,
          currencyDecimals: 2,
        ),
        isNull,
      );
    });

    test('dos separadores decimales son inválidos', () {
      expect(
        DecimalAmountParser.parse(
          '1.2.3',
          convention: DecimalConvention.dot,
          currencyDecimals: 2,
        ),
        isNull,
      );
    });
  });

  group('DecimalAmountParser.format — inverso para export', () {
    test('1999 centavos con 2 decimales exporta "19.99"', () {
      expect(DecimalAmountParser.format(1999, currencyDecimals: 2), '19.99');
    });

    test('COP (0 decimales) exporta el entero sin punto', () {
      expect(DecimalAmountParser.format(45000, currencyDecimals: 0), '45000');
    });

    test('centavos menores a la escala llevan ceros a la izquierda', () {
      expect(DecimalAmountParser.format(5, currencyDecimals: 2), '0.05');
    });
  });
}
