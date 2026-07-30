import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/category_breakdown_item.dart';
import '../../cubit/category_breakdown_state.dart';
import '../report_card.dart';
import '../states/chart_empty_view.dart';
import '../states/chart_skeleton_view.dart';
import 'category_breakdown_row.dart';
import 'category_donut_chart.dart';
import 'category_view_subcategories_link.dart';

/// The `Card Categorías` content (HU-03): the donut, the "Mayor gasto" line
/// and the flat desglose (`A3zxf`) closed by a single "Ver subcategorías"/
/// "Atrás" pill.
///
/// Holds its own drill-down state: the donut starts at the root breakdown
/// and, once the user selects a root category with subcategories and taps
/// the pill, re-renders showing that category's subcategories — same
/// tap/selection rules apply at that level. "Atrás" returns to the root.
/// This local state resets whenever a fresh [state] arrives (new period), so
/// switching the shared range never leaves a stale drill-down behind.
class CategoryBreakdownCardContent extends StatefulWidget {
  const CategoryBreakdownCardContent({
    required this.state,
    required this.rangeCaption,
    required this.onAddMovement,
    this.onOpenCategoryMovements,
    this.boundaryKey,
    super.key,
  });

  final CategoryBreakdownState state;
  final String rangeCaption;
  final VoidCallback onAddMovement;

  /// Navigates to Movimientos filtered by the tapped row's category id and
  /// the active Gráficas period. `null` while the destination is unwired.
  final ValueChanged<String>? onOpenCategoryMovements;

  /// See `ReportCard.boundaryKey`.
  final GlobalKey? boundaryKey;

  @override
  State<CategoryBreakdownCardContent> createState() =>
      _CategoryBreakdownCardContentState();
}

class _CategoryBreakdownCardContentState
    extends State<CategoryBreakdownCardContent> {
  /// The root category currently drilled into, or `null` at the root level.
  CategoryBreakdownItem? _drilledInto;

  /// Selection within the level currently shown (root items, or
  /// `_drilledInto`'s subcategories).
  int? _selectedIndex;

  @override
  void didUpdateWidget(CategoryBreakdownCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.breakdown != widget.state.breakdown) {
      // A new breakdown (period change, refresh) invalidates any in-place
      // drill-down/selection — never carry stale indices into new data.
      _drilledInto = null;
      _selectedIndex = null;
    }
  }

  void _onSectionTap(int? index) {
    setState(() => _selectedIndex = index);
  }

  void _drillIn(List<CategoryBreakdownItem> currentItems) {
    final selected = _selectedIndex;
    if (selected == null || selected >= currentItems.length) {
      return;
    }
    final category = currentItems[selected];
    if (category.subcategories.isEmpty) {
      return;
    }
    setState(() {
      _drilledInto = category;
      _selectedIndex = null;
    });
  }

  void _goBack() {
    setState(() {
      _drilledInto = null;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    if (widget.state.isLoading || widget.state.breakdown == null) {
      return ReportCard(
        title: l10n.reportsCategoriesCardTitle,
        subtitle: '',
        boundaryKey: widget.boundaryKey,
        child: const ChartSkeletonView(
          showHero: false,
          showNote: false,
          shape: ChartSkeletonShape.donut,
        ),
      );
    }

    final breakdown = widget.state.breakdown!;
    if (breakdown.isEmpty) {
      return ReportCard(
        title: l10n.reportsCategoriesCardTitle,
        subtitle: '',
        boundaryKey: widget.boundaryKey,
        child: SizedBox(
          // Same height as `CashflowCardContent`'s empty state: `EmptyState`
          // (`jmQO5`) needs ~296pt to render without overflow (icon 88 +
          // spacings + text + CTA 52), and Pencil has no dedicated
          // card-level empty frame for this tab to size against — 330 keeps
          // the three chart cards' empty states visually consistent.
          height: 330,
          child: ChartEmptyView(onAddMovement: widget.onAddMovement),
        ),
      );
    }

    final rootItems = breakdown.items;
    final drilledInto = _drilledInto;
    final currentItems = drilledInto?.subcategories ?? rootItems;
    final currentTotal = drilledInto == null
        ? breakdown.totalMinor
        : currentItems.fold<int>(0, (sum, item) => sum + item.amountMinor);
    final top = currentItems.reduce(
      (a, b) => b.amountMinor > a.amountMinor ? b : a,
    );
    final topPct = currentTotal == 0
        ? 0
        : (top.amountMinor * 100 / currentTotal).round();
    final topName = top.isUncategorized
        ? l10n.reportsCategoriesUncategorized
        : (top.name ?? '');

    final selected = _selectedIndex;
    final hasValidSelection =
        selected != null && selected < currentItems.length;
    final linkState = drilledInto != null
        ? CategoryDrillDownLinkState.back
        : (hasValidSelection && currentItems[selected].subcategories.isNotEmpty
            ? CategoryDrillDownLinkState.viewSubcategories
            : CategoryDrillDownLinkState.disabled);

    return ReportCard(
      title: l10n.reportsCategoriesCardTitle,
      subtitle: l10n.reportsCategoriesSubtitle(
        currentItems.length,
        widget.rangeCaption,
        drilledInto != null ? 'true' : 'false',
      ),
      boundaryKey: widget.boundaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CategoryDonutChart(
              items: currentItems,
              totalMinor: currentTotal,
              selectedIndex: hasValidSelection ? selected : null,
              onSectionTap: _onSectionTap,
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
          for (final item in currentItems) ...[
            CategoryBreakdownRow(
              item: item,
              totalMinor: currentTotal,
              onTap: item.categoryId == null ||
                      widget.onOpenCategoryMovements == null
                  ? null
                  : () => widget.onOpenCategoryMovements!(item.categoryId!),
            ),
            const SizedBox(height: 8),
          ],
          CategoryViewSubcategoriesLink(
            state: linkState,
            onTap: drilledInto != null ? _goBack : () => _drillIn(currentItems),
          ),
        ],
      ),
    );
  }
}
