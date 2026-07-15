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
  static int toMinor(num major) => (major * _minorPerMajor).round();

  /// Converts minor units to a major value (`1234` → `12.34`). Use only for
  /// display/formatting, never to store or do arithmetic on amounts.
  static double toMajor(int amountMinor) => amountMinor / _minorPerMajor;
}
