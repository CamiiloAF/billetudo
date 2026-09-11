import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_period_option.dart';
import '../../domain/entities/transaction_filter.dart';
import '../utils/date_period_label.dart';
import '../utils/date_period_navigation.dart';
import 'period_nav_arrow_button.dart';

/// `Period Nav Bar` (`u6sSAc` in `O2xuVc`, `w9Eszi` in `ufP4y` —
/// `design-system/billetudo/pages/transacciones.md` § "Period Nav Bar en la
/// pantalla principal"): the Movimientos screen's own period stepper, shown
/// only while `filter.hasDateFilter || filter.hasBudgetPeriodFilter` — the
/// caller (`TransactionsPage`) owns that condition, this widget always
/// renders its card once built.
///
/// Card `$surface`/`stroke:$border`/`cornerRadius:16` with a centered 17/700
/// `Period Label` and two 44×44 chevrons; a Presupuesto filter additionally
/// shows a `Budget Context Tag` (icon + budget name) above the stepper row.
class PeriodNavBar extends StatelessWidget {
  const PeriodNavBar({
    required this.filter,
    required this.budgetOptions,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final TransactionFilter filter;

  /// Resolves the active `filter.budgetPeriod`'s name/icon for the `Budget
  /// Context Tag` — same list `TransactionsListState.budgetOptions` already
  /// keeps for the Presupuesto chip.
  final List<BudgetPeriodOption> budgetOptions;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final budgetPeriod = filter.budgetPeriod;
    final activePeriod = budgetPeriod ?? filter.datePeriod;
    final hasPrevious = budgetPeriod != null
        ? budgetPeriod.hasPrevious
        : datePeriodHasPrevious(activePeriod);
    final hasNext = budgetPeriod != null
        ? budgetPeriod.hasNext
        : datePeriodHasNext(activePeriod, DateTime.now());
    final budgetOption = budgetPeriod == null
        ? null
        : _findOption(budgetOptions, budgetPeriod.budgetId!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (budgetOption != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryAppearance.iconForOrPlaceholder(budgetOption.icon),
                    size: 13,
                    color: colors.primaryOnSoftStrong,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      budgetOption.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryOnSoftStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PeriodNavArrowButton(
                icon: LucideIcons.chevronLeft,
                enabled: hasPrevious,
                onTap: onPrevious,
                semanticLabel: l10n.transactionsPeriodNavPreviousLabel,
              ),
              Expanded(
                child: Text(
                  datePeriodLabel(activePeriod),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              PeriodNavArrowButton(
                icon: LucideIcons.chevronRight,
                enabled: hasNext,
                onTap: onNext,
                semanticLabel: l10n.transactionsPeriodNavNextLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static BudgetPeriodOption? _findOption(
    List<BudgetPeriodOption> options,
    String budgetId,
  ) {
    for (final option in options) {
      if (option.budgetId == budgetId) {
        return option;
      }
    }
    return null;
  }
}
