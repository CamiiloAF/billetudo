import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/net_worth_state.dart';
import '../chart_legend_item.dart';
import '../report_card.dart';
import '../states/chart_empty_view.dart';
import '../states/chart_history_insufficient_banner.dart';
import '../states/chart_skeleton_view.dart';
import 'net_worth_hero.dart';
import 'net_worth_line_chart.dart';

/// The `Card Patrimonio` content (HU-02): resolves [NetWorthState] into
/// loading/empty/normal.
class NetWorthCardContent extends StatelessWidget {
  const NetWorthCardContent({
    required this.state,
    required this.onAddMovement,
    this.boundaryKey,
    super.key,
  });

  final NetWorthState state;
  final VoidCallback onAddMovement;

  /// See `ReportCard.boundaryKey`.
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();

    if (state.isLoading || state.series == null) {
      return ReportCard(
        title: l10n.reportsNetWorthCardTitle,
        subtitle: '',
        boundaryKey: boundaryKey,
        child: const ChartSkeletonView(
          showHero: false,
          showNote: false,
          shape: ChartSkeletonShape.line,
        ),
      );
    }

    final series = state.series!;
    if (series.points.every((p) => p.liquidMinor == 0 && p.totalMinor == 0)) {
      return ReportCard(
        title: l10n.reportsNetWorthCardTitle,
        subtitle: '',
        boundaryKey: boundaryKey,
        child: SizedBox(
          // Same height as `CashflowCardContent`'s empty state: `EmptyState`
          // (`jmQO5`) needs ~296pt to render without overflow (icon 88 +
          // spacings + text + CTA 52), and Pencil has no dedicated
          // card-level empty frame for this tab to size against — 330 keeps
          // the three chart cards' empty states visually consistent.
          height: 330,
          child: ChartEmptyView(onAddMovement: onAddMovement),
        ),
      );
    }

    final points = series.points;
    final last = points.last;
    final subtitle = l10n.reportsNetWorthSubtitle(
      DateFormat.MMMM(locale).format(points.first.date),
      DateFormat.MMMd(locale).format(last.date),
      'COP',
    );

    return ReportCard(
      title: l10n.reportsNetWorthCardTitle,
      subtitle: subtitle,
      boundaryKey: boundaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NetWorthHero(liquidMinor: last.liquidMinor, totalMinor: last.totalMinor),
          if (series.bounds.isClamped) ...[
            const SizedBox(height: 12),
            const ChartHistoryInsufficientBanner(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ChartLegendItem(
                color: colors.sky,
                label: l10n.reportsNetWorthLegendLiquid,
              ),
              const SizedBox(width: 14),
              ChartLegendItem(
                color: colors.primaryData,
                label: l10n.reportsNetWorthLegendTotal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetWorthLineChart(points: points),
          const SizedBox(height: 12),
          Text(
            l10n.reportsNetWorthCaption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
