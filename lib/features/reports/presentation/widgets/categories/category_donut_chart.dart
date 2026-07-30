import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../domain/entities/category_breakdown_item.dart';

/// The Categorías donut (HU-03), replacing `Z6yttn`'s static Pencil arcs
/// with `fl_chart`'s `PieChart`. Tap-to-reveal (criterion 20): tapping a
/// section highlights it and shows its exact amount via `PieTouchData`.
class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    required this.items,
    required this.totalMinor,
    this.currencyCode = 'COP',
    this.size = 156,
    super.key,
  });

  final List<CategoryBreakdownItem> items;
  final int totalMinor;
  final String currencyCode;
  final double size;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const money = MoneyFormatter();
    final touchedIndex = _touchedIndex;
    final centerAmount = touchedIndex != null && touchedIndex < widget.items.length
        ? widget.items[touchedIndex].amountMinor
        : widget.totalMinor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: widget.size * 0.365,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.touchedSection == null) {
                    setState(() => _touchedIndex = null);
                    return;
                  }
                  setState(
                    () => _touchedIndex =
                        response!.touchedSection!.touchedSectionIndex,
                  );
                },
              ),
              sections: [
                for (var i = 0; i < widget.items.length; i++)
                  PieChartSectionData(
                    value: widget.items[i].amountMinor.toDouble(),
                    color: _colorFor(colors, widget.items[i]),
                    radius: i == touchedIndex ? 20 : 16,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Text(
            money.formatSymbol(centerAmount, currencyCode: widget.currencyCode),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(AppColors colors, CategoryBreakdownItem item) => item.isUncategorized
      ? colors.textSecondary
      : CategoryAppearance.colorFor(colors, item.color);
}
