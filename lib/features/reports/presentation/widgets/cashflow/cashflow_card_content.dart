import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/date_range.dart' as domain;
import '../../cubit/cashflow_state.dart';
import '../../cubit/reports_shell_state.dart';
import '../../models/reports_period_selection.dart';
import '../chart_legend_item.dart';
import '../report_card.dart';
import '../states/chart_empty_view.dart';
import '../states/chart_history_insufficient_banner.dart';
import '../states/chart_skeleton_view.dart';
import 'cashflow_bar_chart.dart';
import 'cashflow_net_hero.dart';

/// The `Card Flujo` content (HU-01): resolves [CashflowState] into
/// loading/empty/normal, folding the debt toggle into the hero and legend.
/// Extracted from `CashflowTabView` into its own public widget per this
/// project's `avoid_private_widgets` convention.
class CashflowCardContent extends StatelessWidget {
  const CashflowCardContent({
    required this.state,
    required this.shell,
    required this.onAddMovement,
    required this.onViewCategories,
    this.boundaryKey,
    super.key,
  });

  final CashflowState state;
  final ReportsShellState shell;
  final VoidCallback onAddMovement;
  final VoidCallback onViewCategories;

  /// See `ReportCard.boundaryKey`.
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    if (state.isLoading || state.series == null) {
      return ReportCard(
        title: l10n.reportsCashflowCardTitle,
        subtitle: l10n.reportsCashflowCardSubtitle,
        boundaryKey: boundaryKey,
        child: const ChartSkeletonView(),
      );
    }

    final series = state.series!;
    if (series.isEmpty) {
      // HU-06 "Flujo — vacío" (`NPXSP`): unlike every other card state, the
      // empty state is NOT wrapped in `Report Card` (no border/shadow) and
      // has no toggle below it — just `Chart Tabs` + `Period Row` + `Empty
      // State` on the bare background. `CashflowTabView` skips
      // `CashflowDebtToggle` for this same case.
      final empty = SizedBox(
        height: 330,
        child: ChartEmptyView(onAddMovement: onAddMovement),
      );
      if (boundaryKey == null) {
        return empty;
      }
      return RepaintBoundary(key: boundaryKey, child: empty);
    }

    final points = series.points;
    // includeDebtMovements == true means "integrated" (merged), so debt IS
    // folded into income/expense here; the reverse when the toggle asks to
    // separate it. See `CashflowDebtToggle` doc for the naming direction.
    final totalIncomeMerged = points.fold<int>(
      0,
      (sum, p) =>
          sum +
          p.incomeMinor +
          (shell.includeDebtMovements ? p.debtIncomeMinor : 0),
    );
    final totalExpenseMerged = points.fold<int>(
      0,
      (sum, p) =>
          sum +
          p.expenseMinor +
          (shell.includeDebtMovements ? p.debtExpenseMinor : 0),
    );
    final net = totalIncomeMerged - totalExpenseMerged;

    final isShortHistory = series.bounds.isClamped;
    final periodPhrase =
        !isShortHistory && shell.period.kind == ReportsPeriodKind.lastSixMonths
            ? l10n.reportsCashflowPeriodPhraseLastMonths(6)
            : l10n.reportsCashflowPeriodPhraseGeneric;
    final shortHistoryDays = series.bounds.effectiveRange.endExclusive
        .difference(series.bounds.effectiveRange.start)
        .inDays;

    return ReportCard(
      title: l10n.reportsCashflowCardTitle,
      subtitle: l10n.reportsCashflowCardSubtitle,
      boundaryKey: boundaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashflowNetHero(
            netMinor: net,
            incomeMinor: totalIncomeMerged,
            expenseMinor: totalExpenseMerged,
            periodPhrase: periodPhrase,
            isShortHistory: isShortHistory,
            shortHistoryDays: shortHistoryDays,
            onViewCategories: net < 0 ? onViewCategories : null,
          ),
          if (isShortHistory) ...[
            const SizedBox(height: 12),
            const ChartHistoryInsufficientBanner(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ChartLegendItem(
                color: colors.teal,
                label: l10n.reportsCashflowIncomeLabel,
              ),
              const SizedBox(width: 14),
              ChartLegendItem(
                color: colors.indigo,
                label: l10n.reportsCashflowExpenseLabel,
              ),
              if (!shell.includeDebtMovements) ...[
                const SizedBox(width: 14),
                ChartLegendItem(
                  color: colors.peach,
                  label: l10n.reportsCashflowDebtLegendLabel,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          CashflowBarChart(
            points: points,
            granularity: series.bounds.effectiveRange.granularity,
            includeDebtMovements: shell.includeDebtMovements,
          ),
          if (_isCurrentMonthNote(series.bounds.effectiveRange)) ...[
            const SizedBox(height: 12),
            Text(
              l10n.reportsCashflowCurrentMonthNote(
                DateFormat.MMM(Localizations.localeOf(context).toString())
                    .format(points.last.periodStart)
                    .toLowerCase(),
                clock.now().day,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// True when the last bucket is the current calendar month and the
  /// granularity is monthly — the note that tells the user July "va en
  /// curso: llega hasta el 24" is only meaningful there.
  bool _isCurrentMonthNote(domain.DateRange effectiveRange) {
    if (effectiveRange.granularity != domain.DateGranularity.monthly) {
      return false;
    }
    final now = clock.now();
    final lastBucketStart = DateTime(
      effectiveRange.endExclusive.year,
      effectiveRange.endExclusive.month - 1,
    );
    return lastBucketStart.year == now.year &&
        lastBucketStart.month == now.month;
  }
}
