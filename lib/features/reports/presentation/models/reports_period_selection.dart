import 'package:equatable/equatable.dart';

import '../../domain/entities/date_range.dart';

/// How the shared period of Gráficas e informes was chosen, from the Period
/// Selector sheet (`Sy92N`). Carries the resolved [DateRange] so every tab
/// cubit can query with it directly — only `kind` decides how
/// `PeriodSelector`/`ChartPeriodRow` caption it.
///
/// The `.pen` sheet is only speced for its base case (single month/year
/// stepper + a custom-range escape hatch); see
/// `design-system/billetudo/pages/graficas.md` "Pendientes conocidos". This
/// is `flutter-dev`'s reading of that base case, not a literal mockup replay.
enum ReportsPeriodKind { lastSixMonths, month, year, custom }

class ReportsPeriodSelection extends Equatable {
  const ReportsPeriodSelection({required this.kind, required this.range});

  final ReportsPeriodKind kind;
  final DateRange range;

  /// The screen's default (HU-01): trailing 6 calendar months including the
  /// current one, e.g. opened in July 2026 → February through July.
  factory ReportsPeriodSelection.lastSixMonths({DateTime? now}) {
    final today = now ?? DateTime.now();
    final endExclusive = DateTime(today.year, today.month + 1);
    final start = DateTime(today.year, today.month - 5);
    return ReportsPeriodSelection(
      kind: ReportsPeriodKind.lastSixMonths,
      range: DateRange(
        start: start,
        endExclusive: endExclusive,
        granularity: DateGranularity.monthly,
      ),
    );
  }

  /// A single calendar month, requested as daily buckets — same shape as the
  /// automatic "historial insuficiente" clamp (HU-06), just user-chosen.
  factory ReportsPeriodSelection.month(DateTime monthStart) {
    final start = DateTime(monthStart.year, monthStart.month);
    return ReportsPeriodSelection(
      kind: ReportsPeriodKind.month,
      range: DateRange(
        start: start,
        endExclusive: DateTime(start.year, start.month + 1),
        granularity: DateGranularity.daily,
      ),
    );
  }

  /// A single calendar year, monthly buckets.
  factory ReportsPeriodSelection.year(int year) => ReportsPeriodSelection(
        kind: ReportsPeriodKind.year,
        range: DateRange(
          start: DateTime(year),
          endExclusive: DateTime(year + 1),
          granularity: DateGranularity.monthly,
        ),
      );

  /// An explicit `[start, endExclusive)` window from
  /// `DateRangePickerSheet`. Requested as monthly — `ResolveEffectiveDateRange`
  /// (domain) is what actually decides monthly vs. daily once it knows the
  /// span, so this value never leaks into a query.
  factory ReportsPeriodSelection.custom({
    required DateTime start,
    required DateTime endExclusive,
  }) =>
      ReportsPeriodSelection(
        kind: ReportsPeriodKind.custom,
        range: DateRange(
          start: start,
          endExclusive: endExclusive,
          granularity: DateGranularity.monthly,
        ),
      );

  @override
  List<Object?> get props => [kind, range];
}
