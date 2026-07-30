import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../domain/entities/category_breakdown_item.dart';

/// The Categorías donut (HU-03), replacing `Z6yttn`'s static Pencil arcs
/// with `fl_chart`'s `PieChart`.
///
/// Selection is **persistent, not tap-and-hold**: tapping a section selects
/// it until another tap deselects it or picks a different one — never two
/// sections highlighted at once. Selection lives in the parent
/// (`CategoryBreakdownCardContent`), which also needs it to drive the
/// "Ver subcategorías"/"Atrás" pill, so this widget takes [selectedIndex] and
/// [onSectionTap] instead of holding its own touch state.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    required this.items,
    required this.totalMinor,
    required this.selectedIndex,
    required this.onSectionTap,
    this.currencyCode = 'COP',
    this.size = 156,
    super.key,
  });

  final List<CategoryBreakdownItem> items;
  final int totalMinor;

  /// The currently selected section, or `null` when none is selected.
  final int? selectedIndex;

  /// Called with the new selection: the tapped index, or `null` when the
  /// already-selected section was tapped again (toggle off).
  final ValueChanged<int?> onSectionTap;

  final String currencyCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const money = MoneyFormatter();
    final selected = selectedIndex;
    final hasValidSelection =
        selected != null && selected >= 0 && selected < items.length;
    final centerAmount =
        hasValidSelection ? items[selected].amountMinor : totalMinor;
    final centerName = hasValidSelection
        ? (items[selected].isUncategorized
            ? AppLocalizations.of(context).reportsCategoriesUncategorized
            : (items[selected].name ?? ''))
        : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.365,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) {
                    return;
                  }
                  final tappedIndex =
                      response?.touchedSection?.touchedSectionIndex;
                  if (tappedIndex == null || tappedIndex < 0) {
                    return;
                  }
                  onSectionTap(
                      tappedIndex == selectedIndex ? null : tappedIndex);
                },
              ),
              sections: [
                for (var i = 0; i < items.length; i++)
                  PieChartSectionData(
                    value: items[i].amountMinor.toDouble(),
                    color: _colorFor(colors, items[i]),
                    radius: i == selectedIndex ? 20 : 16,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerName != null) ...[
                Text(
                  centerName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                money.formatSymbol(centerAmount, currencyCode: currencyCode),
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
        ],
      ),
    );
  }

  Color _colorFor(AppColors colors, CategoryBreakdownItem item) =>
      item.isUncategorized
          ? colors.textSecondary
          : CategoryAppearance.colorFor(colors, item.color);
}
