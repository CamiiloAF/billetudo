import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import 'chart_skeleton_hero.dart';
import 'chart_skeleton_plot.dart';

/// The plot geometry a [ChartSkeletonView] should mimic, matching each
/// data-tab card's real chart per `design-system/billetudo/pages/
/// graficas.md`'s "Carga" rule ("skeleton con la geometría real del
/// gráfico"): Flujo (`ITx4K`) is `BarChart`, Patrimonio is `LineChart`
/// (`khZjH` — the `.pen`'s bars there are a Pencil tool limitation, not the
/// spec) and Categorías is a donut (`A3zxf`). Neither Patrimonio nor
/// Categorías has its own "carga" frame in the `.pen`, so their skeletons
/// are inferred from that rule rather than a dedicated nodeId.
enum ChartSkeletonShape { bars, line, donut }

/// HU-06 "carga": skeleton with the chart's real geometry — a 330px plot
/// reserving the current-month note's space, and **uniform** placeholders
/// (a varied skeleton would suggest real data, per
/// `design-system/billetudo/pages/graficas.md`). Reused by the three
/// data-tab cards (Flujo `ITx4K` bars; Patrimonio/Categorías use [shape] to
/// match their own chart type instead of reusing the bars verbatim). The
/// tabs and period selector around it stay interactive — only this card
/// enters "carga".
class ChartSkeletonView extends StatelessWidget {
  const ChartSkeletonView({
    this.columnCount = 6,
    this.showHero = true,
    this.showNote = true,
    this.shape = ChartSkeletonShape.bars,
    super.key,
  });

  final int columnCount;
  final bool showHero;
  final bool showNote;

  /// Which geometry the plot placeholder draws. Defaults to [ChartSkeletonShape.bars]
  /// (Flujo's real chart); Patrimonio/Categorías pass [ChartSkeletonShape.line]/
  /// [ChartSkeletonShape.donut] to match their own real chart's shape.
  final ChartSkeletonShape shape;

  static const double _plotHeight = 330;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.reportsChartSkeletonLoadingLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHero) ...[
            const ChartSkeletonHero(),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 76,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.skeleton,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 62,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.skeleton,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _plotHeight,
            child: ChartSkeletonPlot(
              shape: shape,
              columnCount: columnCount,
              skeletonColor: colors.skeleton,
            ),
          ),
          if (showNote) ...[
            const SizedBox(height: 12),
            Container(
              width: 190,
              height: 14,
              decoration: BoxDecoration(
                color: colors.skeleton,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
