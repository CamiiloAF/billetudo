import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/chart_history_bounds.dart';
import '../../domain/entities/date_range.dart';
import '../models/reports_period_selection.dart';

/// Shared date/period formatting for Gráficas e informes: the
/// `PeriodSelector` label, the `ChartPeriodRow` caption, and the
/// "historial insuficiente" variant of that caption.
abstract final class ReportsPeriodFormat {
  const ReportsPeriodFormat._();

  /// The `PeriodSelector` button label (`lxWG8/ZHpJw`), e.g. "Últimos 6
  /// meses", "Julio 2026", "2026" or the range itself for a custom pick.
  static String selectorLabel(
    AppLocalizations l10n,
    ReportsPeriodSelection selection,
    String locale,
  ) =>
      switch (selection.kind) {
        ReportsPeriodKind.lastSixMonths => l10n.reportsPeriodLastMonths(6),
        ReportsPeriodKind.month =>
          _capitalize(DateFormat.yMMMM(locale).format(selection.range.start)),
        ReportsPeriodKind.year => DateFormat.y(locale).format(
            selection.range.start,
          ),
        ReportsPeriodKind.custom => rangeCaption(selection.range, locale),
      };

  /// The `ChartPeriodRow` caption (`c2u8DB/Hwqal`) for a normal (non-clamped)
  /// range, e.g. "feb – jul 2026".
  static String rangeCaption(DateRange range, String locale) {
    final lastInclusive = DateTime(
      range.endExclusive.year,
      range.endExclusive.month,
      range.endExclusive.day,
    ).subtract(const Duration(days: 1));
    final monthFmt = DateFormat.MMM(locale);
    final yearFmt = DateFormat.y(locale);
    final startMonth = monthFmt.format(range.start).toLowerCase();
    final endMonth = monthFmt.format(lastInclusive).toLowerCase();
    if (range.start.year == lastInclusive.year) {
      return '$startMonth – $endMonth ${yearFmt.format(lastInclusive)}';
    }
    return '$startMonth ${yearFmt.format(range.start)} – '
        '$endMonth ${yearFmt.format(lastInclusive)}';
  }

  /// The "historial insuficiente" caption (HU-06): "N días con datos" instead
  /// of the requested range, once `bounds.isClamped` is true.
  static String historyCaption(
    AppLocalizations l10n,
    ChartHistoryBounds bounds,
  ) {
    final days = bounds.effectiveRange.endExclusive
        .difference(bounds.effectiveRange.start)
        .inDays;
    return l10n.reportsPeriodDaysWithData(days);
  }

  /// The Period Selector's own label override in the "historial
  /// insuficiente" state (`bSh1c/ZHpJw`): "Desde el 22 jul".
  static String historySelectorLabel(
    AppLocalizations l10n,
    ChartHistoryBounds bounds,
    String locale,
  ) {
    final start = bounds.effectiveRange.start;
    return l10n.reportsPeriodSinceDate(DateFormat.MMMd(locale).format(start));
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
