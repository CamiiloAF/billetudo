import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/category_breakdown_state.dart';
import '../report_card.dart';
import '../states/chart_empty_view.dart';
import '../states/chart_skeleton_view.dart';
import 'category_breakdown_row.dart';
import 'category_donut_chart.dart';
import 'category_view_subcategories_link.dart';

/// The `Card Categorías` content (HU-03): the donut, the "Mayor gasto" line
/// and the flat desglose (`A3zxf`) closed by a single "Ver subcategorías"
/// link — no per-row accordion.
class CategoryBreakdownCardContent extends StatelessWidget {
  const CategoryBreakdownCardContent({
    required this.state,
    required this.rangeCaption,
    required this.onAddMovement,
    this.onViewSubcategories,
    this.boundaryKey,
    super.key,
  });

  final CategoryBreakdownState state;
  final String rangeCaption;
  final VoidCallback onAddMovement;

  /// See `CategoryViewSubcategoriesLink.onTap` — nullable while the
  /// destination remains undesigned.
  final VoidCallback? onViewSubcategories;

  /// See `ReportCard.boundaryKey`.
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    if (state.isLoading || state.breakdown == null) {
      return ReportCard(
        title: l10n.reportsCategoriesCardTitle,
        subtitle: '',
        boundaryKey: boundaryKey,
        child: const ChartSkeletonView(showHero: false, showNote: false),
      );
    }

    final breakdown = state.breakdown!;
    if (breakdown.isEmpty) {
      return ReportCard(
        title: l10n.reportsCategoriesCardTitle,
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

    final items = breakdown.items;
    final top = items.first;
    final topPct = breakdown.totalMinor == 0
        ? 0
        : (top.amountMinor * 100 / breakdown.totalMinor).round();
    final topName = top.isUncategorized
        ? l10n.reportsCategoriesUncategorized
        : (top.name ?? '');

    return ReportCard(
      title: l10n.reportsCategoriesCardTitle,
      subtitle: l10n.reportsCategoriesSubtitle(items.length, rangeCaption),
      boundaryKey: boundaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CategoryDonutChart(
              items: items,
              totalMinor: breakdown.totalMinor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reportsCategoriesTopLabel(topName, topPct),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            CategoryBreakdownRow(item: item, totalMinor: breakdown.totalMinor),
            const SizedBox(height: 8),
          ],
          CategoryViewSubcategoriesLink(onTap: onViewSubcategories),
        ],
      ),
    );
  }
}
