import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/core/utils/money_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Caret behaviour is where an as-you-type money mask breaks (and where no
/// golden would ever notice), so every edit here is expressed as the exact
/// `TextEditingValue` pair the framework hands the formatter: what the field
/// held, and what it would hold if nobody intervened.
void main() {
  const cop = MoneyInputFormatter(decimals: 0);
  const usd = MoneyInputFormatter(decimals: 2);

  /// The user types [char] at [at] over [text] (whose caret sat at [at]).
  TextEditingValue typeAt(
    MoneyInputFormatter formatter,
    String text,
    String char,
    int at,
  ) =>
      formatter.formatEditUpdate(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: at),
        ),
        TextEditingValue(
          text: text.substring(0, at) + char + text.substring(at),
          selection: TextSelection.collapsed(offset: at + char.length),
        ),
      );

  /// Backspace with the caret at [at] (deletes the character before it).
  TextEditingValue backspaceAt(
    MoneyInputFormatter formatter,
    String text,
    int at,
  ) =>
      formatter.formatEditUpdate(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: at),
        ),
        TextEditingValue(
          text: text.substring(0, at - 1) + text.substring(at),
          selection: TextSelection.collapsed(offset: at - 1),
        ),
      );

  group('typing', () {
    test('groups the figure keystroke by keystroke, caret at the end', () {
      var value = TextEditingValue.empty;
      for (final digit in '4500000'.split('')) {
        value = typeAt(cop, value.text, digit, value.text.length);
      }

      expect(value.text, '4.500.000');
      expect(value.selection.baseOffset, 9);
    });

    test('a digit typed in the middle keeps the caret behind it', () {
      final value = typeAt(cop, '4.500.000', '9', 1);

      expect(value.text, '49.500.000');
      expect(value.selection.baseOffset, 2);
    });

    test('a digit typed right before a separator does not jump the caret', () {
      // '45|.000' + '6' → '456.000' with the caret still after the 6.
      final value = typeAt(cop, '45.000', '6', 2);

      expect(value.text, '456.000');
      expect(value.selection.baseOffset, 3);
    });

    test('a keystroke that pushes a new group keeps the caret on its digit',
        () {
      // '9|99.000' + '1' → '9.199.000': a dot appears *before* the caret, so a
      // naive offset would leave the caret one character behind.
      final value = typeAt(cop, '999.000', '1', 1);

      expect(value.text, '9.199.000');
      expect(value.selection.baseOffset, 3);
    });

    test('leading zeros are dropped and the caret follows them', () {
      final value = typeAt(cop, '0', '5', 1);

      expect(value.text, '5');
      expect(value.selection.baseOffset, 1);
    });
  });

  group('deleting', () {
    test('backspacing onto a separator deletes the digit before it', () {
      // '4.500|.000' → the dot is not the user's target, the 0 in front is.
      final value = backspaceAt(cop, '4.500.000', 6);

      expect(value.text, '450.000');
      expect(value.selection.baseOffset, 3);
    });

    test('backspacing a digit regroups and keeps the caret in place', () {
      final value = backspaceAt(cop, '4.500.000', 9);

      expect(value.text, '450.000');
      expect(value.selection.baseOffset, 7);
    });

    test('the field can be emptied back to nothing', () {
      final value = backspaceAt(cop, '4', 1);

      expect(value.text, '');
    });

    test('deleting every digit but through separators still empties', () {
      final value = cop.formatEditUpdate(
        const TextEditingValue(text: '4.500'),
        const TextEditingValue(text: '.'),
      );

      expect(value.text, '');
    });

    test('selecting all and deleting empties instead of falling back to 0', () {
      final value = cop.formatEditUpdate(
        const TextEditingValue(
          text: '4.500.000',
          selection: TextSelection(baseOffset: 0, extentOffset: 9),
        ),
        TextEditingValue.empty,
      );

      expect(value.text, '');
    });
  });

  group('pasting', () {
    test('a bare run of digits comes out grouped', () {
      final value = cop.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1234567',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );

      expect(value.text, '1.234.567');
      expect(value.selection.baseOffset, 9);
    });

    test('an already formatted amount is not multiplied by its own dots', () {
      final value = cop.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: r'$ 1.234.567',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );

      expect(value.text, '1.234.567');
    });

    test('an oversized run is capped instead of overflowing the integer', () {
      final value = cop.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: '9' * 30,
          selection: const TextSelection.collapsed(offset: 30),
        ),
      );

      expect(value.text.replaceAll('.', '').length, 15);
      expect(int.parse(value.text.replaceAll('.', '')), isPositive);
    });
  });

  group('decimals', () {
    test('a currency with cents keeps them and stops at its precision', () {
      var value = TextEditingValue.empty;
      for (final char in '1234,567'.split('')) {
        value = typeAt(usd, value.text, char, value.text.length);
      }

      expect(value.text, '1.234,56');
      expect(value.selection.baseOffset, 8);
    });

    test('a dot typed on a keyboard without a comma acts as the separator', () {
      final value = typeAt(usd, '12', '.', 2);

      expect(value.text, '12,');
      expect(value.selection.baseOffset, 3);
    });

    test('a leading separator reads as zero point something', () {
      final value = typeAt(usd, '', ',', 0);

      expect(value.text, '0,');
      expect(value.selection.baseOffset, 2);
    });

    test('a second separator is refused', () {
      final value = typeAt(usd, '1,5', ',', 3);

      expect(value.text, '1,5');
    });

    test('COP refuses the separator instead of merging the cents in', () {
      final value = cop.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1.234,56',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );

      expect(value.text, '1.234');
    });
  });

  group('sign', () {
    test('a negative amount keeps its sign when negatives are allowed', () {
      const signed = MoneyInputFormatter(decimals: 0, allowNegative: true);
      final value = signed.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '-1234',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );

      expect(value.text, '-1.234');
      expect(value.selection.baseOffset, 6);
    });

    test('the sign is dropped where negatives are not allowed', () {
      final value = cop.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '-1234',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );

      expect(value.text, '1.234');
    });
  });

  group('round trip', () {
    test('what the mask writes is what MoneyFormatter reads back', () {
      var value = TextEditingValue.empty;
      for (final digit in '4500000'.split('')) {
        value = typeAt(cop, value.text, digit, value.text.length);
      }

      expect(MoneyFormatter.parseMinor(value.text), 450000000);
    });

    test('a formatted amount survives the mask untouched', () {
      const money = MoneyFormatter();
      final text = money.formatAmount(123456, decimalDigits: 2);
      final value = usd.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );

      expect(value.text, text);
      expect(MoneyFormatter.parseMinor(value.text), 123456);
    });
  });
}
