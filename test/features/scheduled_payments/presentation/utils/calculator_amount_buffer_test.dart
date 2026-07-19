import 'package:billetudo/features/scheduled_payments/presentation/utils/calculator_amount_buffer.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart'
    show CalcOperator;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorAmountBuffer: entrada de dígitos', () {
    test('empieza en 0 y va formando el entero en centavos, no un double', () {
      const buffer = CalculatorAmountBuffer();
      final result = buffer
          .digitPressed(1, currency: 'COP')
          .digitPressed(2, currency: 'COP')
          .digitPressed(3, currency: 'COP');

      expect(result.amountMinor, 12300);
      expect(result.amountMinor, isA<int>());
    });

    test('el punto decimal habilita centavos exactos', () {
      const buffer = CalculatorAmountBuffer();
      final result = buffer
          .digitPressed(1, currency: 'USD')
          .decimalPressed(currency: 'USD')
          .digitPressed(5, currency: 'USD')
          .digitPressed(0, currency: 'USD');

      expect(result.amountMinor, 150);
    });

    test('una moneda sin decimales ignora el punto decimal', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 100);
      final result = buffer.decimalPressed(currency: 'COP');

      expect(result.amountMinor, 100);
      expect(result.entryFractionDigits, -1);
    });
  });

  group('CalculatorAmountBuffer: operadores', () {
    test('suma: 100 + 50 = 150 (en centavos)', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 10000); // $100.00
      final afterOperator = buffer.operatorPressed(CalcOperator.add);
      final afterOperand =
          afterOperator.digitPressed(5, currency: 'COP').digitPressed(0, currency: 'COP');
      final result = afterOperand.equalsPressed();

      expect(result.amountMinor, 15000);
    });

    test('resta nunca produce un monto negativo', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 500);
      final result = buffer
          .operatorPressed(CalcOperator.subtract)
          .digitPressed(9, currency: 'COP')
          .digitPressed(9, currency: 'COP')
          .digitPressed(9, currency: 'COP')
          .equalsPressed();

      expect(result.amountMinor, 0);
    });

    test('multiplicación redondea al centavo más cercano', () {
      // $2.00 * $1.50 = $3.00 exacto, sin residuo de coma flotante.
      const buffer = CalculatorAmountBuffer(amountMinor: 200);
      final result = buffer
          .operatorPressed(CalcOperator.multiply)
          .digitPressed(1, currency: 'USD')
          .decimalPressed(currency: 'USD')
          .digitPressed(5, currency: 'USD')
          .equalsPressed();

      expect(result.amountMinor, 300);
    });

    test('dividir entre cero no rompe, devuelve el operando izquierdo', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 500);
      final result = buffer
          .operatorPressed(CalcOperator.divide)
          .digitPressed(0, currency: 'COP')
          .equalsPressed();

      expect(result.amountMinor, 500);
    });
  });

  group('CalculatorAmountBuffer: backspace', () {
    test('borra el último dígito entero', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 12300);
      final result = buffer.backspacePressed();

      expect(result.amountMinor, 1200);
    });

    test('borra el último dígito decimal sin tocar los enteros', () {
      final buffer = const CalculatorAmountBuffer()
          .digitPressed(5, currency: 'USD')
          .decimalPressed(currency: 'USD')
          .digitPressed(9, currency: 'USD');
      final result = buffer.backspacePressed();

      expect(result.amountMinor, 500);
    });

    test('tras evaluar con =, backspace edita el resultado, no el cálculo previo', () {
      const buffer = CalculatorAmountBuffer(amountMinor: 10000);
      final evaluated = buffer
          .operatorPressed(CalcOperator.add)
          .digitPressed(5, currency: 'COP')
          .equalsPressed();
      expect(evaluated.amountMinor, 10500); // $105.00

      final result = evaluated.backspacePressed();
      // Borra el último dígito entero del *resultado* ($105.00 -> $10.00),
      // no vuelve a exponer el operando ($100) que ya quedó consumido por =.
      expect(result.amountMinor, 1000);
      expect(result.justEvaluated, isFalse);
    });
  });
}
