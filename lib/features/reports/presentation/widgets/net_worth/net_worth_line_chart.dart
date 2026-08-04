import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../domain/entities/net_worth_point.dart';

/// The Patrimonio plot: **`LineChart`, never `BarChart`** (criterion 8).
///
/// The `.pen`'s `VBliq` "Net Worth Bar Column" draws bars only because
/// Pencil cannot draw a line series — `design-system/billetudo/pages/
/// graficas.md` calls this out explicitly as a tool limitation, not the
/// spec. Two series: líquido (`$sky`) and total (`$primary-data`).
class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    required this.points,
    this.currencyCode = 'COP',
    this.height = 236,
    super.key,
  });

  final List<NetWorthPoint> points;
  final String currencyCode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    const money = MoneyFormatter();

    // Only show a bottom-axis label when the bucket's month differs from
    // the last one that got a label (or it's the final point), so daily
    // granularity never repeats the same month on consecutive ticks.
    final labelIndices = <int>{};
    String? lastLabel;
    for (var i = 0; i < points.length; i++) {
      final label = _bucketLabel(points[i].date, locale);
      final isLast = i == points.length - 1;
      if (label != lastLabel || isLast) {
        labelIndices.add(i);
        lastLabel = label;
      }
    }

    final liquidSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      liquidSpots.add(FlSpot(i.toDouble(), points[i].liquidMinor / 100));
      totalSpots.add(FlSpot(i.toDouble(), points[i].totalMinor / 100));
    }

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 3,
        );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.textPrimary,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${_bucketLabel(points[spot.x.round()].date, locale)}\n'
                    '${money.formatSymbol(spot.barIndex == 0 ? points[spot.x.round()].liquidMinor : points[spot.x.round()].totalMinor, currencyCode: currencyCode)}',
                    TextStyle(
                      color: colors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                // fl_chart auto-computes its own "nice" interval (1, 2, 5,
                // 10, 20…) when this is left null, so it only calls
                // `getTitlesWidget` at its own evenly-spaced ticks — not once
                // per spot index. That silently drops whichever entries in
                // `labelIndices` don't land on one of those ticks (verified
                // live: with 49 daily points, fl_chart chose interval 5,
                // which skips index 17 — the "ago" transition — entirely).
                // Forcing interval 1 makes it call back for every index, so
                // our own dedup is what actually decides what renders.
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final isLast = index == points.length - 1;
                  if (!labelIndices.contains(index)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _bucketLabel(points[index].date, locale),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                        color:
                            isLast ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            line(liquidSpots, colors.sky),
            line(totalSpots, colors.primaryData),
          ],
        ),
      ),
    );
  }

  String _bucketLabel(DateTime date, String locale) =>
      DateFormat('MMM', locale).format(date).toLowerCase();
}
