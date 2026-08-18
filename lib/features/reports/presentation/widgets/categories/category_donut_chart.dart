import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
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
    this.size = defaultSize,
    super.key,
  });

  /// The donut's outer diameter.
  ///
  /// Pencil (`Z6yttn`) draws it at 156, sized around an 11-character total
  /// (`$19.190.000`). That is too tight in Flutter for the same figure: a
  /// real Colombian monthly expense of 7 significant digits (`$2.640.000`)
  /// needs ~98pt at the design's 16pt/w800, and a two-decimal currency needs
  /// ~127pt. Enlarging the ring (approved over abbreviating the figure, which
  /// the "Tesis" of `pages/graficas.md` forbids: every amount is shown in
  /// full) widens the hole proportionally instead of shrinking the number.
  static const double defaultSize = 184;

  /// Design ratios from the Pencil arcs (`innerRadius: 0.73`), kept as
  /// fractions of [size] so enlarging the donut scales the hole and the ring
  /// together instead of leaving a thin ring in an oversized box.
  static const double _holeRadiusRatio = 0.365;
  static const double _ringThicknessRatio = 0.135;

  /// How much wider the selected section's ring is drawn. Pencil offsets the
  /// slice radially ("exploded slice"); `fl_chart` has no such offset, so the
  /// selection reads through a thicker arc instead.
  static const double _selectedRingBonus = 4;

  /// Breathing room between the center label and the ring, in total. Pencil's
  /// center frame is 116 wide against a 113.9 hole, i.e. it deliberately uses
  /// the hole edge to edge; 4 keeps long totals from kissing the arcs.
  static const double _centerInset = 4;

  /// The center total's design size, and the smallest it may auto-shrink to
  /// before the figure would rather clip than become unreadable. Shrinking is
  /// the tail-end fallback for extreme amounts (8+ digits with decimals); the
  /// widened ring covers every realistic case at [_maxAmountFontSize].
  static const double _maxAmountFontSize = 16;
  static const double _minAmountFontSize = 12;

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

    final centerText =
        money.formatSymbol(centerAmount, currencyCode: currencyCode);
    final amountStyle = (Theme.of(context).textTheme.titleSmall ??
            const TextStyle(fontFamily: AppTheme.fontFamily))
        .copyWith(
      fontSize: _maxAmountFontSize,
      fontWeight: FontWeight.w800,
      color: colors.textPrimary,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * _holeRadiusRatio,
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
                    radius: i == selectedIndex
                        ? size * _ringThicknessRatio + _selectedRingBonus
                        : size * _ringThicknessRatio,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          SizedBox(
            // Constrains the label to the donut's hole (centerSpaceRadius *
            // 2) minus some breathing room, so `TextOverflow.ellipsis` on
            // `centerName` actually has a bound to clip against instead of
            // growing past the ring on long category names.
            width: _centerWidth,
            child: Column(
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
                  centerText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: amountStyle.copyWith(
                    fontSize: _amountFontSize(context, centerText, amountStyle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The usable width inside the ring: the hole's diameter less
  /// [_centerInset].
  double get _centerWidth => size * _holeRadiusRatio * 2 - _centerInset;

  /// The design's [_maxAmountFontSize] whenever [text] fits inside
  /// [_centerWidth], otherwise the largest size that does, floored at
  /// [_minAmountFontSize] so the figure never becomes unreadable. The total is
  /// never abbreviated (`$2,6M`): `pages/graficas.md` requires full figures.
  /// Stepped down rather than scaled by the overflow ratio because
  /// `letterSpacing` is absolute in Flutter, so text width is not proportional
  /// to [TextStyle.fontSize] and a single ratio undershoots.
  double _amountFontSize(BuildContext context, String text, TextStyle style) {
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    for (var fontSize = _maxAmountFontSize;
        fontSize > _minAmountFontSize;
        fontSize -= 0.5) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      if (painter.width <= _centerWidth) {
        return fontSize;
      }
    }
    return _minAmountFontSize;
  }

  Color _colorFor(AppColors colors, CategoryBreakdownItem item) =>
      item.isUncategorized
          ? colors.textSecondary
          : CategoryAppearance.colorFor(colors, item.color);
}
