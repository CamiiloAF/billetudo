import 'package:intl/intl.dart';

import '../../domain/entities/date_period_filter.dart';

/// "Julio 2026" — HU-06b's Month granularity label (`P5fSkK`'s "Period
/// Label", and the Chip Fecha default it mirrors): the full month name,
/// capitalized, plus the year. `intl`'s Spanish month names come back
/// lowercase ("julio 2026"), so this capitalizes the first letter — shared
/// by the date filter stepper and the Chip Fecha so both agree.
String monthYearLabel(DateTime anchor) {
  final raw = DateFormat('MMMM yyyy', 'es_CO').format(anchor);
  if (raw.isEmpty) {
    return raw;
  }
  return raw[0].toUpperCase() + raw.substring(1);
}

/// "Este mes" / "Julio 2026" / "3 jul - 9 jul" / a custom range — whatever
/// best names [period], shared by the Chip Fecha and the date filter sheet's
/// stepper so both read the same label for the same period.
String datePeriodLabel(DatePeriodFilter period) {
  if (period.isCustomRange) {
    return _rangeLabel(period);
  }
  return switch (period.granularity!) {
    DateGranularity.week => _rangeLabel(period),
    DateGranularity.month => monthYearLabel(period.anchor!),
    DateGranularity.year => DateFormat.y('es_CO').format(period.anchor!),
  };
}

String _rangeLabel(DatePeriodFilter period) {
  final format = DateFormat.MMMd('es_CO');
  final end = period.endExclusive.subtract(const Duration(days: 1));
  return '${format.format(period.start)} - ${format.format(end)}';
}
