import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chart_view.dart';
import 'chart_tab_item.dart';

/// The `Chart Tabs` component (`I1Jgk`, `reusable:true`): 4 pill tabs,
/// segmented-control chrome, kept **outside** the tab's own scrollable — see
/// `design-system/billetudo/pages/graficas.md` D1: it stays pinned under the
/// `Page Header` on every tab, including Resumen.
class ChartTabs extends StatelessWidget {
  const ChartTabs({required this.active, required this.onSelected, super.key});

  final ChartViewId active;
  final ValueChanged<ChartViewId> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (ChartViewId.dashboard, l10n.reportsTabSummary),
      (ChartViewId.cashflow, l10n.reportsTabCashflow),
      (ChartViewId.netWorth, l10n.reportsTabNetWorth),
      (ChartViewId.categoryBreakdown, l10n.reportsTabCategories),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (id, label) in tabs)
            Expanded(
              child: ChartTabItem(
                label: label,
                selected: id == active,
                onTap: () => onSelected(id),
              ),
            ),
        ],
      ),
    );
  }
}
