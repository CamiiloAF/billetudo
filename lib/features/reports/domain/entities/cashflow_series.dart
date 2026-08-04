import 'package:equatable/equatable.dart';

import 'cashflow_point.dart';
import 'chart_history_bounds.dart';

/// The full flujo de caja report (HU-01): one [CashflowPoint] per bucket,
/// ordered ascending by [CashflowPoint.periodStart], plus the toggle state it
/// was built with and the history-clamp info for the "historial
/// insuficiente" state (HU-06).
class CashflowSeries extends Equatable {
  const CashflowSeries({
    required this.points,
    required this.includeDebtMovements,
    required this.bounds,
  });

  final List<CashflowPoint> points;

  /// The toggle value this series was requested with (default `true` =
  /// movimientos de deuda integrados). Echoed back so the presentation layer
  /// does not need to track it separately from the stream it renders.
  final bool includeDebtMovements;

  final ChartHistoryBounds bounds;

  /// True when every point is exactly zero across all four amounts — HU-06
  /// "vacío" (cero movimientos en el rango).
  bool get isEmpty => points.every(
        (p) =>
            p.incomeMinor == 0 &&
            p.expenseMinor == 0 &&
            p.debtIncomeMinor == 0 &&
            p.debtExpenseMinor == 0,
      );

  @override
  List<Object?> get props => [points, includeDebtMovements, bounds];
}
