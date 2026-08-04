import 'package:intl/intl.dart';

import '../../domain/entities/budget_period_option.dart';

/// "3 jul - 9 jul" — the Presupuesto filter sheet's row label for a budget's
/// current period window ([BudgetPeriodOption.start]/[BudgetPeriodOption.
/// endExclusive]), mirroring the date filter's own range formatting so both
/// read the same.
String budgetPeriodOptionRangeLabel(BudgetPeriodOption option) {
  final format = DateFormat.MMMd('es_CO');
  final end = option.endExclusive.subtract(const Duration(days: 1));
  return '${format.format(option.start)} - ${format.format(end)}';
}
