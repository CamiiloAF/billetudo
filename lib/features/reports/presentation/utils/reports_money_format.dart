import '../../../../core/utils/money_formatter.dart';

/// Signed money formatting for report heroes (HU-01/HU-02): a leading `+`/`−`
/// (U+2212, not a hyphen) **before** the `$`, e.g. `+$6.460.000` /
/// `−$1.180.000` — `MoneyFormatter.formatSymbol` alone would put the sign
/// *inside* the digits (`$-1.180.000`), which the negative-balance frame
/// (`V1PNE`) never shows. Kept local to Gráficas e informes: no other screen
/// asked for a signed figure yet, so this is not promoted to
/// `core/utils/money_formatter.dart` speculatively.
abstract final class ReportsMoneyFormat {
  const ReportsMoneyFormat._();

  static String signed(
    int amountMinor, {
    required String currencyCode,
    String locale = 'es_CO',
  }) {
    const money = MoneyFormatter();
    final sign = amountMinor < 0 ? '−' : '+';
    final digits = money.formatSymbol(
      amountMinor.abs(),
      currencyCode: currencyCode,
      locale: locale,
    );
    return '$sign$digits';
  }
}
