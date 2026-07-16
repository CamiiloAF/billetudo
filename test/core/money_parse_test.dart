import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter.parseMinor — centavos enteros', () {
    test('0,01 es exactamente 1 centavo (sin error de redondeo)', () {
      expect(MoneyFormatter.parseMinor('0,01'), 1);
    });

    test('parsea decimales con coma (notación es-CO)', () {
      expect(MoneyFormatter.parseMinor('12,34'), 1234);
      expect(MoneyFormatter.parseMinor('24,5'), 2450);
      expect(MoneyFormatter.parseMinor('0,1'), 10);
    });

    test('parsea enteros sin separador decimal', () {
      expect(MoneyFormatter.parseMinor('1234'), 123400);
      expect(MoneyFormatter.parseMinor('0'), 0);
    });

    test('el punto es separador de miles en es-CO', () {
      expect(MoneyFormatter.parseMinor('1.234'), 123400);
      expect(MoneyFormatter.parseMinor('1.234.567'), 123456700);
    });

    test('combina miles y decimales', () {
      expect(MoneyFormatter.parseMinor('1.234,56'), 123456);
      expect(MoneyFormatter.parseMinor('1.000.000,99'), 100000099);
    });

    test('acepta el punto decimal del teclado numérico', () {
      expect(MoneyFormatter.parseMinor('24.5'), 2450);
      expect(MoneyFormatter.parseMinor('12.34'), 1234);
    });

    test('ignora el símbolo de moneda y los espacios', () {
      expect(MoneyFormatter.parseMinor(r'$ 1.234,56'), 123456);
      expect(MoneyFormatter.parseMinor(' 12,34 '), 1234);
    });

    test('parsea montos negativos', () {
      expect(MoneyFormatter.parseMinor('-12,34'), -1234);
      expect(MoneyFormatter.parseMinor('-0,01'), -1);
    });

    test('redondea media hacia arriba los dígitos sobrantes', () {
      expect(MoneyFormatter.parseMinor('0,005'), 1);
      expect(MoneyFormatter.parseMinor('0,004'), 0);
      expect(MoneyFormatter.parseMinor('12,345'), 1235);
      // El acarreo cruza el entero sin perder un centavo.
      expect(MoneyFormatter.parseMinor('0,999'), 100);
    });

    test('no pierde precisión en montos grandes (donde el double falla)', () {
      // 8.999.999.999.999,99 en centavos supera 2^53 como decimal en coma
      // flotante; con enteros es exacto.
      expect(
        MoneyFormatter.parseMinor('8.999.999.999.999,99'),
        899999999999999,
      );
    });

    test('rechaza texto que no es un monto', () {
      expect(MoneyFormatter.parseMinor(''), isNull);
      expect(MoneyFormatter.parseMinor('   '), isNull);
      expect(MoneyFormatter.parseMinor('abc'), isNull);
      expect(MoneyFormatter.parseMinor('12,34,56'), isNull);
      expect(MoneyFormatter.parseMinor('12a'), isNull);
      expect(MoneyFormatter.parseMinor('-'), isNull);
    });
  });

  group('MoneyFormatter.parseRateBps — puntos básicos enteros', () {
    test('24,5 % son 2450 puntos básicos', () {
      expect(MoneyFormatter.parseRateBps('24,5'), 2450);
    });

    test('convierte tasas típicas de tarjeta', () {
      expect(MoneyFormatter.parseRateBps('0'), 0);
      expect(MoneyFormatter.parseRateBps('1'), 100);
      expect(MoneyFormatter.parseRateBps('24,5'), 2450);
      expect(MoneyFormatter.parseRateBps('29,99'), 2999);
      expect(MoneyFormatter.parseRateBps('100'), 10000);
    });

    test('el resultado es siempre un entero', () {
      expect(MoneyFormatter.parseRateBps('24,5'), isA<int>());
    });

    test('rechaza una tasa que no es número', () {
      expect(MoneyFormatter.parseRateBps('n/a'), isNull);
    });
  });
}
