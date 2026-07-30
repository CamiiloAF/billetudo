import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import 'chart_skeleton_hero.dart';

/// HU-06 "carga": skeleton with the chart's real geometry — a 330px plot
/// reserving the current-month note's space, and **uniform-height** bars
/// (a varied skeleton would suggest real data, per
/// `design-system/billetudo/pages/graficas.md`). Reused by the three
/// data-tab cards (Flujo `ITx4K`, and the same shape for Patrimonio/
/// Categorías, not separately framed in the `.pen`); the tabs and period
/// selector around it stay interactive — only this card enters "carga".
class ChartSkeletonView extends StatelessWidget {
  const ChartSkeletonView({
    this.columnCount = 6,
    this.showHero = true,
    this.showNote = true,
    super.key,
  });

  final int columnCount;
  final bool showHero;
  final bool showNote;

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < columnCount; i++)
                  Container(
                    width: 13,
                    height: 250,
                    decoration: BoxDecoration(
                      color: colors.skeleton,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
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
