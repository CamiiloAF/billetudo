import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

/// Formats and parses amounts. **Project golden rule:** money is ALWAYS stored
/// as integers in minor units (cents); never `double`. This helper is the only
/// place that converts between that representation and the text the user sees.
///
/// Multi-currency note: for now the minor unit is assumed to be 1/100 (cents),
/// consistent with the storage convention. Reconciling currencies with a
/// different number of decimals is defined in `10-multi-moneda.md`.
@lazySingleton
class MoneyFormatter {
  const MoneyFormatter();

  static const int _minorPerMajor = 100;

  /// `1234, currencyCode: 'COP'` → `"$1.234,00"` (per [locale]).
  String format(
    int amountMinor, {
    required String currencyCode,
    String locale = 'es_CO',
  }) {
    final formatter = NumberFormat.currency(locale: locale, name: currencyCode);
    return formatter.format(amountMinor / _minorPerMajor);
  }

  /// Same as [format] but without the currency code/symbol (digits only).
  String formatAmount(int amountMinor, {String locale = 'es_CO'}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    return formatter.format(amountMinor / _minorPerMajor);
  }

  /// Converts a major value (e.g. `12.34`) to minor units (`1234`).
  ///
  /// Only for values that are already numbers. To read **user input** use
  /// [parseMinor]: it never goes through `double`, so it cannot introduce a
  /// rounding error.
  static int toMinor(num major) => (major * _minorPerMajor).round();

  /// Converts minor units to a major value (`1234` → `12.34`). Use only for
  /// display/formatting, never to store or do arithmetic on amounts.
  static double toMajor(int amountMinor) => amountMinor / _minorPerMajor;

  /// Parses typed money into cents: `'12,34'` → `1234`, `'0,01'` → `1`.
  /// Returns `null` when the text is not a valid amount.
  ///
  /// Pure integer arithmetic on the digits — the text never becomes a `double`,
  /// so `'0,01'` cannot land on 0.999… and lose a cent.
  static int? parseMinor(String input) => parseScaled(input);

  /// Parses a typed annual rate into whole basis points: `'24,5'` (%) → `2450`.
  /// Basis points are just percent scaled by 100, hence the same conversion.
  static int? parseRateBps(String input) => parseScaled(input);

  /// Parses [input] into an integer scaled by 10^[decimals], with no `double`
  /// involved. Digits beyond [decimals] are rounded half-up.
  ///
  /// Accepts Spanish notation (`'1.234,56'`) and a plain decimal point
  /// (`'24.5'`). When both separators appear, the last one is the decimal one
  /// and the other is grouping; with a single `'.'` followed by exactly three
  /// digits it is read as grouping (`'1.234'` → 1234), per es-CO convention.
  static int? parseScaled(String input, {int decimals = 2}) {
    final sanitized = input.replaceAll(_ignorablePattern, '');
    if (sanitized.isEmpty) {
      return null;
    }

    final negative = sanitized.startsWith('-');
    final unsigned = sanitized.replaceFirst(_signPattern, '');
    if (unsigned.isEmpty || !_numberPattern.hasMatch(unsigned)) {
      return null;
    }

    // A comma is only ever a decimal separator here (es-CO groups with '.'), so
    // repeating it is not a number: '12,34,56' must be rejected, never read as
    // 123456.
    if (!unsigned.contains('.') && ','.allMatches(unsigned).length > 1) {
      return null;
    }

    final decimalSeparator = _decimalSeparatorOf(unsigned);
    final digitsOnly = decimalSeparator == null
        ? unsigned.replaceAll(_separatorPattern, '')
        : null;

    final String integerDigits;
    final String fractionDigits;
    if (digitsOnly != null) {
      integerDigits = digitsOnly;
      fractionDigits = '';
    } else {
      final index = unsigned.lastIndexOf(decimalSeparator!);
      integerDigits =
          unsigned.substring(0, index).replaceAll(_separatorPattern, '');
      fractionDigits = unsigned.substring(index + 1);
    }

    if (fractionDigits.contains(_separatorPattern)) {
      return null;
    }

    final integerPart = integerDigits.isEmpty ? 0 : int.tryParse(integerDigits);
    if (integerPart == null) {
      return null;
    }

    final padded = fractionDigits.padRight(decimals + 1, '0');
    final kept = padded.substring(0, decimals);
    final fractionPart = kept.isEmpty ? 0 : int.tryParse(kept);
    if (fractionPart == null) {
      return null;
    }
    // Half-up on the first dropped digit: never silently shave a cent off.
    final roundUp = int.parse(padded[decimals]) >= 5 ? 1 : 0;

    final scale = _pow10(decimals);
    final value = integerPart * scale + fractionPart + roundUp;
    return negative ? -value : value;
  }

  /// Which of `.` / `,` acts as the decimal separator, or `null` when the text
  /// has no decimals.
  static String? _decimalSeparatorOf(String value) {
    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    if (lastDot < 0 && lastComma < 0) {
      return null;
    }
    if (lastDot >= 0 && lastComma >= 0) {
      return lastDot > lastComma ? '.' : ',';
    }

    final separator = lastDot >= 0 ? '.' : ',';
    final index = lastDot >= 0 ? lastDot : lastComma;
    if (separator.allMatches(value).length > 1) {
      return null; // '1.234.567': grouping only.
    }
    final trailingDigits = value.length - index - 1;
    // '1.234' is one thousand two hundred thirty four in es-CO; '1,234' is not.
    if (separator == '.' && trailingDigits == 3) {
      return null;
    }
    return separator;
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static final RegExp _ignorablePattern = RegExp(r'[\s $]');
  static final RegExp _signPattern = RegExp(r'^[-+]');
  static final RegExp _separatorPattern = RegExp(r'[.,]');
  static final RegExp _numberPattern = RegExp(r'^\d[\d.,]*$|^[.,]\d+$');
}
