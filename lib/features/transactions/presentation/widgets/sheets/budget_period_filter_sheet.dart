import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';
import '../../../domain/entities/budget_period_option.dart';
import '../../../domain/entities/date_period_filter.dart';
import '../../cubit/budget_period_filter_cubit.dart';
import '../../utils/budget_period_label.dart';

/// What the "Presupuesto" filter sheet resolves with when the user taps
/// "Aplicar": distinguishes "applied, no budget chosen" ([window] `null`,
/// i.e. the user tapped "Limpiar" then "Aplicar") from "dismissed without
/// applying" — `show` itself resolving to `null` — so the caller never
/// confuses "the filter was explicitly cleared" with "nothing changed".
class BudgetPeriodFilterResult {
  const BudgetPeriodFilterResult(this.window);

  /// The chosen budget's current period, or `null` when cleared.
  final DatePeriodFilter? window;
}

/// HU-06's "Presupuesto" chip sheet: single-selection (a movement can only be
/// filtered by one budget's period at a time, unlike the multi-select account
/// sheet) over the live list of active budgets, each showing its name, icon
/// and current period window (re-resolved live on every open — see
/// [BudgetPeriodFilterCubit]).
class BudgetPeriodFilterSheet extends StatelessWidget {
  const BudgetPeriodFilterSheet({this.initialBudgetId, super.key});

  /// The filter's current budget id, or `null` when no budget is applied.
  final String? initialBudgetId;

  static Future<BudgetPeriodFilterResult?> show(
    BuildContext context, {
    String? initialBudgetId,
  }) async {
    final cubit = getIt<BudgetPeriodFilterCubit>();
    unawaited(cubit.start(initialBudgetId));
    final applied = await BottomSheetBase.show<BudgetPeriodFilterResult>(
      context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const BudgetPeriodFilterSheetBody(),
      ),
    );
    await cubit.close();
    return applied;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<BudgetPeriodFilterCubit>();
        unawaited(cubit.start(initialBudgetId));
        return cubit;
      },
      child: const BudgetPeriodFilterSheetBody(),
    );
  }
}

class BudgetPeriodFilterSheetBody extends StatelessWidget {
  const BudgetPeriodFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<BudgetPeriodFilterCubit, BudgetPeriodFilterState>(
      builder: (context, state) {
        final cubit = context.read<BudgetPeriodFilterCubit>();
        final selected = _selectedOption(state);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A sheet title is 17/700 in billetudo.pen, which is what
            // `SheetHead` renders.
            SheetHead(title: l10n.budgetPeriodFilterSheetTitle),
            const SizedBox(height: 16),
            if (state.options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: BudgetPeriodFilterEmptyState(
                  message: l10n.budgetPeriodFilterEmptyMessage,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = state.options[index];
                    return BudgetPeriodOptionRow(
                      option: option,
                      selected: state.selectedBudgetId == option.budgetId,
                      onTap: () => cubit.select(option.budgetId),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: cubit.clear,
                child: Text(l10n.commonClear),
              ),
              right: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  BudgetPeriodFilterResult(
                    selected == null
                        ? null
                        : DatePeriodFilter.budget(
                            budgetId: selected.budgetId,
                            start: selected.start,
                            endExclusive: selected.endExclusive,
                          ),
                  ),
                ),
                child: Text(l10n.commonApply),
              ),
            ),
          ],
        );
      },
    );
  }

  BudgetPeriodOption? _selectedOption(BudgetPeriodFilterState state) {
    final selectedId = state.selectedBudgetId;
    if (selectedId == null) {
      return null;
    }
    for (final option in state.options) {
      if (option.budgetId == selectedId) {
        return option;
      }
    }
    return null;
  }
}

/// One row of the sheet: icon, name and current period window on the left, a
/// trailing `check` when [selected] — same visual language as
/// `AccountSelectRow`, radio-style instead of a checkbox since only one
/// budget applies at a time.
class BudgetPeriodOptionRow extends StatelessWidget {
  const BudgetPeriodOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BudgetPeriodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    // MASTER.md: a circular icon-wrap uses half its height
                    // as radius.
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    CategoryAppearance.iconForOrPlaceholder(option.icon),
                    size: 20,
                    color: colors.primaryOnSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        budgetPeriodOptionRangeLabel(option),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          size: 18,
                          color: colors.primaryOnSoft,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's "no active budgets" state — never a bare blank list; guides
/// the user to create a budget elsewhere instead of implying the filter is
/// broken.
class BudgetPeriodFilterEmptyState extends StatelessWidget {
  const BudgetPeriodFilterEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.pieChart, size: 40, color: colors.textSecondary),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
