import '../../domain/entities/date_period_filter.dart';

/// Whether `PeriodStepper`'s "Prev" control should be enabled for [period]:
/// only a granular (week/month/year) Fecha period can step backward — neither
/// a custom range nor a Presupuesto window (handled separately, via
/// `DatePeriodFilter.hasPrevious`) has that concept.
///
/// UX decision (not specified by `design-system/billetudo/pages/
/// transacciones.md`, which only documents the visual states, not the
/// navigation bounds — see its "Pendiente técnico" note): there is no lower
/// bound on how far back a calendar period can go, so "Prev" is always
/// enabled for a granular Fecha period.
bool datePeriodHasPrevious(DatePeriodFilter period) =>
    !period.isCustomRange && !period.isBudgetPeriod;

/// Whether `PeriodStepper`'s "Next" control should be enabled for [period],
/// evaluated against [now].
///
/// UX decision (same caveat as [datePeriodHasPrevious]): Movimientos never
/// lets a granular Fecha period step into the future — once the period shown
/// already contains (or is later than) the one [now] falls in, there is
/// nowhere forward to go, mirroring the mockup's disabled `Next` on "Julio
/// 2026" while that is the current month. A custom range has no granularity
/// to step at all, so it never offers `Next` either.
bool datePeriodHasNext(DatePeriodFilter period, DateTime now) {
  if (period.isCustomRange || period.isBudgetPeriod) {
    return false;
  }
  final currentPeriodStart =
      DatePeriodFilter.granular(period.granularity!, now).start;
  return period.start.isBefore(currentPeriodStart);
}
