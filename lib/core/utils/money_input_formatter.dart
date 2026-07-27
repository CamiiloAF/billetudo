import 'package:flutter/services.dart';

/// Groups a money field's digits **as the user types** (`4500000` →
/// `4.500.000`) while keeping the caret exactly where the user left it.
///
/// Why it exists: money fields used to be formatted only when something
/// outside rebuilt them, so a typed figure stayed a wall of digits. The naive
/// fix (rewrite the text on every keystroke) is what produced the older
/// credit-card complaint — the caret jumped to the end on every key and
/// deleting a separator was impossible. So the caret is not preserved by
/// character offset (which the inserted dots shift) but by **counting
/// significant characters** (digits and the decimal comma) before it: that
/// count survives any regrouping.
///
/// Storage is untouched: this is presentation only. The text it produces is
/// exactly what `MoneyFormatter.parseMinor` already reads (es-CO notation:
/// `.` groups, `,` separates decimals), so a field's `onChanged` keeps parsing
/// straight into minor units and never goes through a `double`.
///
/// Pair it with the decimals the field should accept: text-money fields use
/// the currency's default (`MoneyFormatter.currencyDecimals`, COP takes none,
/// so the separator is refused); the calculator keypad (transactions / pagos
/// programados) uses `MoneyFormatter.inputDecimals`, which allows two for
/// every currency so COP can carry typed cents (item 4).
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({
    required this.decimals,
    this.allowNegative = false,
    this.maxIntegerDigits = 15,
  });

  /// How many decimals the user may type. `0` (COP) rejects the separator.
  final int decimals;

  /// Whether a leading `-` survives. Only the account balance needs it.
  final bool allowNegative;

  /// Ceiling on the integer part, so the parsed value cannot outgrow a 64-bit
  /// integer no matter how long the user leans on a key.
  final int maxIntegerDigits;

  static const String groupSeparator = '.';
  static const String decimalSeparator = ',';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) {
      // The field must stay emptiable: empty text is a null amount, not a `0`
      // the user is then trapped with.
      return newValue;
    }

    final negative = allowNegative && raw.contains('-');
    final caret = newValue.selection.baseOffset < 0
        ? raw.length
        : newValue.selection.baseOffset.clamp(0, raw.length);

    // A '.' the user just typed means a decimal separator (an English keyboard
    // has no comma key); every other '.' is grouping this formatter inserted.
    final typedDecimalIndex = decimals > 0 &&
            raw.length == oldValue.text.length + 1 &&
            caret > 0 &&
            raw[caret - 1] == groupSeparator
        ? caret - 1
        : -1;

    // Everything below works on the "significant" string — digits plus at most
    // one comma, no grouping — and on how many of its characters sit before
    // the caret. Both survive regrouping unchanged.
    final significant = StringBuffer();
    var before = 0;
    var hasDecimal = false;
    var integerDigits = 0;
    var fractionDigits = 0;
    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];
      if (char == decimalSeparator && decimals == 0) {
        // The currency has no cents, so everything from the separator on is
        // not part of the figure: pasting `1.234,56` into a COP field must
        // read 1.234, never 123.456.
        break;
      } else if (decimals > 0 &&
          !hasDecimal &&
          (char == decimalSeparator || i == typedDecimalIndex)) {
        hasDecimal = true;
        significant.write(decimalSeparator);
      } else if (!_isDigit(char)) {
        continue; // Grouping, sign, a second comma or stray punctuation.
      } else if (hasDecimal) {
        if (fractionDigits >= decimals) {
          continue; // Past the currency's precision.
        }
        fractionDigits++;
        significant.write(char);
      } else {
        if (integerDigits >= maxIntegerDigits) {
          continue;
        }
        integerDigits++;
        significant.write(char);
      }
      if (i < caret) {
        before++;
      }
    }

    var text = significant.toString();

    // Backspacing *onto* a separator removes no digit, so regrouping would put
    // the separator straight back and the key would feel dead. Delete the
    // character in front of it instead, which is what the user meant.
    if (newValue.text.length == oldValue.text.length - 1 &&
        oldValue.selection.isCollapsed &&
        _digitCount(oldValue.text) == integerDigits + fractionDigits &&
        before > 0) {
      text = text.substring(0, before - 1) + text.substring(before);
      before--;
    }

    final decimalAt = text.indexOf(decimalSeparator);
    var integer = decimalAt < 0 ? text : text.substring(0, decimalAt);
    final fraction = decimalAt < 0 ? '' : text.substring(decimalAt + 1);
    hasDecimal = decimalAt >= 0;

    // '007' is not a figure: drop the padding and pull the caret back with it.
    final trimmed = integer.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    before -= (integer.length - trimmed.length).clamp(0, before);
    integer = trimmed;

    if (integer.isEmpty) {
      if (!hasDecimal) {
        return TextEditingValue.empty; // Only separators were left.
      }
      integer = '0'; // ',5' reads as '0,5'.
      if (before > 0) {
        before++;
      }
    }

    final formatted = StringBuffer();
    if (negative) {
      formatted.write('-');
    }
    formatted
      ..write(_grouped(integer))
      ..write(hasDecimal ? decimalSeparator : '')
      ..write(fraction);
    final result = formatted.toString();

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: _offsetFor(result, before, negative),
      ),
    );
  }

  /// Inserts a grouping separator every three digits, right to left.
  static String _grouped(String integer) {
    final buffer = StringBuffer();
    for (var i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(groupSeparator);
      }
      buffer.write(integer[i]);
    }
    return buffer.toString();
  }

  /// Where the caret goes so that exactly [significant] significant characters
  /// sit in front of it — grouping dots do not count, which is precisely why
  /// regrouping cannot drag the caret away.
  static int _offsetFor(String text, int significant, bool negative) {
    if (significant <= 0) {
      return negative ? 1 : 0;
    }
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text[i]) || text[i] == decimalSeparator) {
        seen++;
        if (seen == significant) {
          return i + 1;
        }
      }
    }
    return text.length;
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  static int _digitCount(String text) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0x30 && code <= 0x39) {
        count++;
      }
    }
    return count;
  }
}
