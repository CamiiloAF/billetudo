import '../../domain/entities/csv_dialect.dart';

/// Result of [CsvDateParser.parse].
class ParsedCsvDate {
  const ParsedCsvDate({required this.date, required this.ambiguous});

  final DateTime date;

  /// True when both non-year components read `<= 12` (day and month), so the
  /// opposite [DateComponentOrder] would have parsed to an equally valid,
  /// different date — `docs/requirements/fase-1/11-import-export.md` §Fechas: "si
  /// la muestra es ambigua ... la vista previa lo advierte explícitamente".
  final bool ambiguous;
}

/// Parses a date cell per [DateComponentOrder]/[DateSeparatorChar] (never the
/// device locale — the format is part of the mapping, chosen or autodetected
/// per file). [DateComponentOrder.isoYmd] always uses `-`, per
/// `docs/requirements/fase-1/11-import-export.md` §Fechas.
abstract final class CsvDateParser {
  static ParsedCsvDate? parse(
    String raw, {
    required DateComponentOrder order,
    required DateSeparatorChar separator,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // Some third-party exports (e.g. Wallet/BudgetBakers) append a
    // space-separated time-of-day (`2026-07-05 22:14:10`) to the date cell.
    // The mapping only ever asks for a date format, so only the date part
    // before the first space is parsed — the time, if any, is discarded.
    final datePart = trimmed.split(' ').first;

    final separatorChar =
        order == DateComponentOrder.isoYmd ? '-' : _charOf(separator);
    final parts = datePart.split(separatorChar);
    if (parts.length != 3) {
      return null;
    }
    if (parts.any((part) => part.isEmpty || !_digitsOnly.hasMatch(part))) {
      return null;
    }

    final int year;
    final int month;
    final int day;
    switch (order) {
      case DateComponentOrder.isoYmd:
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      case DateComponentOrder.dayMonthYear:
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      case DateComponentOrder.monthDayYear:
        month = int.parse(parts[0]);
        day = int.parse(parts[1]);
        year = int.parse(parts[2]);
    }

    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1000) {
      return null;
    }

    final date = DateTime(year, month, day);
    // `DateTime` silently normalizes an out-of-range day (e.g. Feb 30 rolls
    // into March) instead of throwing — reject anything that did not
    // round-trip, so a malformed date is `invalidDate`, not a wrong one.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return ParsedCsvDate(
      date: date,
      ambiguous: order != DateComponentOrder.isoYmd && day <= 12 && month <= 12,
    );
  }

  static String _charOf(DateSeparatorChar separator) => switch (separator) {
        DateSeparatorChar.dash => '-',
        DateSeparatorChar.slash => '/',
        DateSeparatorChar.dot => '.',
      };

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
}
