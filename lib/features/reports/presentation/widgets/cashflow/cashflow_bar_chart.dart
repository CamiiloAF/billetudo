import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../domain/entities/cashflow_point.dart';
import '../../../domain/entities/date_range.dart';

/// The Flujo de caja bar plot (`lbZWZ` "Cashflow Bar Column", stacked into a
/// `Plot`): ingresos/gastos per bucket, plus a 3rd "deuda" bar when
/// [includeDebtMovements] is `false` (the "Separar movimientos de deuda"
/// toggle is ON). Real bars, not `lbZWZ`'s Pencil rectangles — this is
/// `fl_chart`'s `BarChart`.
///
/// **Multimoneda está fuera de este entregable** (`design-system/billetudo/
/// pages/graficas.md`, nota `O91yc8`): every amount is formatted assuming a
/// single currency, [currencyCode].
///
/// Tap-to-reveal (criterion 20, "no está diseñado todavía" in the `.pen`):
/// `fl_chart`'s built-in touch tooltip is reused as the pattern — tapping a
/// bar surfaces its exact amount and period, the only affordance a
/// scale-less chart has for reading a precise value.
class CashflowBarChart extends StatelessWidget {
  const CashflowBarChart({
    required this.points,
    required this.granularity,
    required this.includeDebtMovements,
    this.currencyCode = 'COP',
    this.height = 330,
    super.key,
  });

  final List<CashflowPoint> points;
  final DateGranularity granularity;
  final bool includeDebtMovements;
  final String currencyCode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const money = MoneyFormatter();

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final income = includeDebtMovements
          ? point.incomeMinor
          : point.incomeMinor + point.debtIncomeMinor;
      final expense = includeDebtMovements
          ? point.expenseMinor
          : point.expenseMinor + point.debtExpenseMinor;
      final debt = includeDebtMovements
          ? 0
          : point.debtIncomeMinor + point.debtExpenseMinor;

      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 3,
          barRods: [
            BarChartRodData(
              toY: income / 100,
              color: colors.teal,
              width: 9,
              borderRadius: BorderRadius.circular(3),
            ),
            BarChartRodData(
              toY: expense / 100,
              color: colors.indigo,
              width: 9,
              borderRadius: BorderRadius.circular(3),
            ),
            if (!includeDebtMovements)
              BarChartRodData(
                toY: debt / 100,
                color: colors.peach,
                width: 9,
                borderRadius: BorderRadius.circular(3),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.textPrimary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= points.length) {
                  return null;
                }
                final point = points[groupIndex];
                final label = _bucketLabel(point.periodStart);
                final amountMinor = includeDebtMovements
                    ? (rodIndex == 0
                        ? point.incomeMinor
                        : point.expenseMinor)
                    : switch (rodIndex) {
                        0 => point.incomeMinor + point.debtIncomeMinor,
                        1 => point.expenseMinor + point.debtExpenseMinor,
                        _ => point.debtIncomeMinor + point.debtExpenseMinor,
                      };
                return BarTooltipItem(
                  '$label\n${money.formatSymbol(amountMinor, currencyCode: currencyCode)}',
                  TextStyle(
                    color: colors.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              
            ),
            rightTitles: const AxisTitles(
              
            ),
            topTitles: const AxisTitles(
              
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final isLast = index == points.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _bucketLabel(points[index].periodStart),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                        color: isLast ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }

  String _bucketLabel(DateTime date) => granularity == DateGranularity.daily
      ? DateFormat('d MMM').format(date)
      : DateFormat('MMM').format(date).toLowerCase();
}
