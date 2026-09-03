import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_range_picker_sheet.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../../categories/domain/entities/category_node.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../domain/entities/budget_period_option.dart';
import '../../../domain/entities/date_period_filter.dart';
import '../../../domain/entities/tag.dart';
import '../../../domain/entities/transaction.dart' show TransactionType;
import '../../../domain/entities/transaction_filter.dart';
import '../../cubit/unified_filters_cubit.dart';
import '../../utils/date_period_label.dart';

/// Issue #7: the unified bottom sheet replacing the Presupuesto/Fecha/Tipo/
/// Categoría/Etiqueta sheets that used to open one at a time from the
/// Movimientos filter bar (cuenta stayed out — see `AccountFilterChipRow`).
/// Fixed section order — `design-system/billetudo/pages/transacciones.md` §
/// "Bottom sheet unificado de filtros" (nodeId `rktqT`): Presupuesto → Fecha
/// → Tipo → Categoría → Etiqueta, then `Sheet Buttons Row`.
class UnifiedFiltersSheet extends StatelessWidget {
  const UnifiedFiltersSheet({
    required this.initialFilter,
    required this.budgetOptions,
    super.key,
  });

  final TransactionFilter initialFilter;
  final List<BudgetPeriodOption> budgetOptions;

  /// Resolves to the [UnifiedFiltersResult] applied via "Aplicar" (or the
  /// header/footer "Limpiar" actions), or `null` if the sheet is dismissed
  /// without applying.
  static Future<UnifiedFiltersResult?> show(
    BuildContext context, {
    required TransactionFilter initialFilter,
    required List<BudgetPeriodOption> budgetOptions,
  }) =>
      BottomSheetBase.show<UnifiedFiltersResult>(
        context,
        builder: (context) => UnifiedFiltersSheet(
          initialFilter: initialFilter,
          budgetOptions: budgetOptions,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<UnifiedFiltersCubit>();
        unawaited(
          cubit.start(filter: initialFilter, budgetOptions: budgetOptions),
        );
        return cubit;
      },
      child: const UnifiedFiltersSheetBody(),
    );
  }
}

class UnifiedFiltersSheetBody extends StatelessWidget {
  const UnifiedFiltersSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<UnifiedFiltersCubit, UnifiedFiltersState>(
      builder: (context, state) {
        final cubit = context.read<UnifiedFiltersCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnifiedFiltersHeader(onClearAll: cubit.clearAll),
            const SizedBox(height: 16),
            const UnifiedFilterDivider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.hasBudgets) ...[
                      const SizedBox(height: 16),
                      BudgetFilterSection(state: state),
                      const SizedBox(height: 16),
                      const UnifiedFilterDivider(),
                    ],
                    const SizedBox(height: 16),
                    DateFilterSection(state: state),
                    const SizedBox(height: 16),
                    const UnifiedFilterDivider(),
                    const SizedBox(height: 16),
                    TypeFilterSection(state: state),
                    const SizedBox(height: 16),
                    const UnifiedFilterDivider(),
                    const SizedBox(height: 16),
                    CategoryFilterSection(state: state),
                    const SizedBox(height: 16),
                    const UnifiedFilterDivider(),
                    const SizedBox(height: 16),
                    TagFilterSection(state: state),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: cubit.clearAll,
                child: Text(l10n.commonClear),
              ),
              right: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(cubit.buildResult()),
                child: Text(l10n.commonApply),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The sheet's title row: "Filtros" + a "Limpiar todo" text action
/// (`H4kfi`/`ja0OE` in `rktqT`).
class UnifiedFiltersHeader extends StatelessWidget {
  const UnifiedFiltersHeader({required this.onClearAll, super.key});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.transactionsUnifiedFiltersTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: onClearAll,
            child: Text(l10n.commonClearAll),
          ),
        ),
      ],
    );
  }
}

/// A section's own divider (`ydPhY`/`EN5PU`/... in `rktqT`), omitted along
/// with the Presupuesto section itself when there are no budgets
/// (criterion #6).
class UnifiedFilterDivider extends StatelessWidget {
  const UnifiedFilterDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.colors.border);
}

/// A section's all-caps 11/700 label (`vQaHr`/`p6Xn2Y`/... in `rktqT`).
class UnifiedFilterSectionLabel extends StatelessWidget {
  const UnifiedFilterSectionLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.colors.textSecondary,
          ),
    );
  }
}

/// One horizontally-scrollable row of `Pill` selections — the shared visual
/// pattern of every section in `rktqT` (`Row` of `Pill — <option>`).
class UnifiedFilterPillRow extends StatelessWidget {
  const UnifiedFilterPillRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}

/// One `Pill — <option>` (`tsQot`/`EFRnB`/... in `rktqT`): a 44px pill with a
/// leading icon and label, `$primary-soft`/`$primary` when selected.
class UnifiedFilterPill extends StatelessWidget {
  const UnifiedFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground = selected ? colors.primaryOnSoftStrong : colors.textSecondary;

    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? colors.primary : colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section — Presupuesto (`nagyZ`): "Ninguno" + one pill per active budget,
/// single-selection. Only rendered while `state.hasBudgets` (criterion #6).
class BudgetFilterSection extends StatelessWidget {
  const BudgetFilterSection({required this.state, super.key});

  final UnifiedFiltersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UnifiedFiltersCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedFilterSectionLabel(label: l10n.transactionsFilterSectionBudget),
        const SizedBox(height: 10),
        UnifiedFilterPillRow(
          children: [
            UnifiedFilterPill(
              label: l10n.transactionsFilterBudgetNone,
              icon: LucideIcons.ban,
              selected: !state.isBudgetActive,
              onTap: cubit.clearBudget,
            ),
            const SizedBox(width: 8),
            for (final option in state.budgetOptions) ...[
              UnifiedFilterPill(
                label: option.name,
                icon: CategoryAppearance.iconForOrPlaceholder(option.icon),
                selected: state.selectedBudgetId == option.budgetId,
                onTap: () => cubit.selectBudget(option.budgetId),
              ),
              if (option != state.budgetOptions.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

/// Section — Fecha (`uY05Y`): granularity switch + stepper, locked (icon
/// `lock` + caption, controls at `opacity: 0.4`) while a Presupuesto filter
/// is active (criterion #9). Also carries the "Rango personalizado" row so
/// HU-06b's custom-range capability keeps working from the unified sheet,
/// even though the abbreviated Pencil mockup for this redesign only shows
/// the granularity/stepper block.
class DateFilterSection extends StatelessWidget {
  const DateFilterSection({required this.state, super.key});

  final UnifiedFiltersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<UnifiedFiltersCubit>();
    final locked = state.isDateLockedByBudget;
    final filter = state.datePeriod;
    final isCustom = filter.isCustomRange;
    final granularityView = isCustom ? DatePeriodFilter.thisMonth() : filter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UnifiedFilterSectionLabel(label: l10n.transactionsFilterSectionDate),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(LucideIcons.lock, size: 12, color: colors.textSecondary),
            ],
          ],
        ),
        if (locked) ...[
          const SizedBox(height: 6),
          Text(
            l10n.transactionsFilterDateLockedByBudget,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
          ),
        ],
        const SizedBox(height: 10),
        IgnorePointer(
          ignoring: locked || isCustom,
          child: Opacity(
            opacity: locked ? 0.4 : (isCustom ? 0.4 : 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<DateGranularity>(
                  segments: [
                    ButtonSegment(
                      value: DateGranularity.week,
                      label: Text(l10n.dateFilterWeek),
                    ),
                    ButtonSegment(
                      value: DateGranularity.month,
                      label: Text(l10n.dateFilterMonth),
                    ),
                    ButtonSegment(
                      value: DateGranularity.year,
                      label: Text(l10n.dateFilterYear),
                    ),
                  ],
                  selected: {granularityView.granularity!},
                  onSelectionChanged: (selection) =>
                      cubit.granularitySelected(selection.first),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => cubit.step(-1),
                      icon: const Icon(LucideIcons.chevronLeft),
                    ),
                    Text(datePeriodLabel(granularityView)),
                    IconButton(
                      onPressed: () => cubit.step(1),
                      icon: const Icon(LucideIcons.chevronRight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: locked,
          child: Opacity(
            opacity: locked ? 0.4 : 1,
            child: UnifiedFilterPillRow(
              children: [
                UnifiedFilterPill(
                  label: isCustom
                      ? l10n.dateFilterRangeLabel(
                          DateFormat.yMMMd('es_CO').format(filter.start),
                          DateFormat.yMMMd('es_CO').format(
                            filter.endExclusive
                                .subtract(const Duration(days: 1)),
                          ),
                        )
                      : l10n.dateFilterCustomRange,
                  icon: LucideIcons.calendarRange,
                  selected: isCustom,
                  onTap: () => _pickCustomRange(context, cubit, filter),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    UnifiedFiltersCubit cubit,
    DatePeriodFilter filter,
  ) async {
    final now = DateTime.now();
    final initialStart = filter.isCustomRange ? filter.start : now;
    final initialEnd = filter.isCustomRange
        ? filter.endExclusive.subtract(const Duration(days: 1))
        : now;
    final range = await DateRangePickerSheet.show(
      context,
      initialStart: initialStart,
      initialEnd: initialEnd,
    );
    if (range == null) {
      return;
    }
    cubit.applyCustomDateRange(start: range.start, end: range.end);
  }
}

/// Display order for the type pills (`X60ozs`/`L29bs`/`lpE6G` in `rktqT`),
/// same order `type_filter_sheet.dart` already uses.
const _typeOrder = [
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
];

/// Section — Tipo (`nOb15`): Gasto/Ingreso/Transferencia, multi-selection.
class TypeFilterSection extends StatelessWidget {
  const TypeFilterSection({required this.state, super.key});

  final UnifiedFiltersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UnifiedFiltersCubit>();
    final labels = {
      TransactionType.expense: l10n.transactionTypeExpense,
      TransactionType.income: l10n.transactionTypeIncome,
      TransactionType.transfer: l10n.transactionTypeTransfer,
    };
    final icons = {
      TransactionType.expense: LucideIcons.trendingDown,
      TransactionType.income: LucideIcons.trendingUp,
      TransactionType.transfer: LucideIcons.arrowLeftRight,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedFilterSectionLabel(label: l10n.transactionsFilterSectionType),
        const SizedBox(height: 10),
        UnifiedFilterPillRow(
          children: [
            for (final type in _typeOrder) ...[
              UnifiedFilterPill(
                label: labels[type]!,
                icon: icons[type],
                selected: state.types.contains(type),
                onTap: () => cubit.toggleType(type),
              ),
              if (type != _typeOrder.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

/// Section — Categoría (`yXu2h`): root categories of both trees (income and
/// expense), the symmetric root/subtree toggle of HU-06. Flat root pills —
/// matching `rktqT`'s mockup, unlike the standalone `CategoryFilterSheet`'s
/// expandable root/subcategory list (still used elsewhere, e.g. Presupuestos'
/// form and Exportar) — so filtering by an individual subcategory from this
/// sheet is not available; only the root/whole-tree granularity is.
class CategoryFilterSection extends StatelessWidget {
  const CategoryFilterSection({required this.state, super.key});

  final UnifiedFiltersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UnifiedFiltersCubit>();
    final nodes = <CategoryNode>[
      ...state.expenseNodes,
      ...state.incomeNodes,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedFilterSectionLabel(
          label: l10n.transactionsFilterSectionCategory,
        ),
        const SizedBox(height: 10),
        UnifiedFilterPillRow(
          children: [
            for (final node in nodes) ...[
              UnifiedFilterPill(
                label: node.root.name,
                icon: CategoryAppearance.iconForOrPlaceholder(node.root.icon),
                selected: state.categoryIds.contains(node.root.id),
                onTap: () => cubit.toggleRootCategory(node),
              ),
              if (node != nodes.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

/// Section — Etiqueta (`Be4V3`): every tag, multi-selection.
class TagFilterSection extends StatelessWidget {
  const TagFilterSection({required this.state, super.key});

  final UnifiedFiltersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UnifiedFiltersCubit>();
    final tags = state.tags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedFilterSectionLabel(label: l10n.transactionsFilterSectionTag),
        const SizedBox(height: 10),
        if (tags.isEmpty)
          Text(
            l10n.transactionsFilterTagEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textSecondary,
                ),
          )
        else
          UnifiedFilterPillRow(
            children: [
              for (final Tag tag in tags) ...[
                UnifiedFilterPill(
                  label: tag.name,
                  selected: state.tagIds.contains(tag.id),
                  onTap: () => cubit.toggleTag(tag.id),
                ),
                if (tag != tags.last) const SizedBox(width: 8),
              ],
            ],
          ),
      ],
    );
  }
}
