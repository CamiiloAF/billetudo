import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period_window.dart';
import '../../domain/entities/budget_progress.dart';
import '../../domain/entities/budget_scope.dart';

/// Shared, localized formatting for the Budgets screens: scope label, temporal
/// anchor, period range and status. Kept in one place so the list, the detail
/// and the history read identically.
abstract final class BudgetFormat {
  const BudgetFormat._();

  static final DateFormat _dayMonth = DateFormat('d MMM', 'es_CO');

  /// Short scope label for the list/detail meta line (HU-04). Warns when the
  /// scope was narrowed but every referent is gone.
  static String scopeLabel(AppLocalizations l10n, BudgetScope scope) {
    if (scope.isStranded) {
      return l10n.budgetScopeStranded;
    }
    if (scope.isGlobal) {
      return l10n.budgetScopeGlobal;
    }
    final parts = <String>[
      if (!scope.isAccountGlobal)
        l10n.budgetScopeAccounts(scope.aliveAccountIds.length),
      if (!scope.isCategoryGlobal)
        l10n.budgetScopeCategories(scope.aliveCategoryIds.length),
    ];
    return parts.join(' · ');
  }

  /// Temporal anchor of the period: recurring budgets "reset on", one-off ones
  /// "end on" (HU-04).
  static String temporalAnchor(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
  ) =>
      budget.isOneOff
          ? l10n.budgetEndsOn(_dayMonth.format(window.lastDay))
          : l10n.budgetResetsOn(_dayMonth.format(window.endExclusive));

  /// The explicit cycle range for the period stepper, e.g. "1–31 jul" or
  /// "21 jul – 20 ago".
  static String rangeLabel(BudgetPeriodWindow window) {
    final start = window.start;
    final last = window.lastDay;
    if (start.year == last.year && start.month == last.month) {
      return '${start.day}–${_dayMonth.format(last)}';
    }
    return '${_dayMonth.format(start)} – ${_dayMonth.format(last)}';
  }

  /// The hero's 2-part left caption: "82% · $492.000 de $600.000".
  static String progressCaption(
    AppLocalizations l10n,
    BudgetProgress progress,
    String currency,
  ) {
    const money = MoneyFormatter();
    return '${l10n.budgetPercent(progress.percent)} · '
        '${l10n.budgetProgressBreakdown(
      money.formatSymbol(progress.spentMinor, currencyCode: currency),
      money.formatSymbol(progress.amountMinor, currencyCode: currency),
    )}';
  }

  /// The period stepper's inner label: "1–31 jul · vigente".
  static String periodStepperLabel(
    AppLocalizations l10n,
    BudgetPeriodWindow window,
  ) =>
      '${rangeLabel(window)} · ${statusLabel(l10n, window.status)}';

  static String statusLabel(
    AppLocalizations l10n,
    BudgetWindowStatus status,
  ) =>
      switch (status) {
        BudgetWindowStatus.current => l10n.budgetPeriodStatusCurrent,
        BudgetWindowStatus.past => l10n.budgetPeriodStatusPast,
        BudgetWindowStatus.future => l10n.budgetPeriodStatusFuture,
      };

  static String periodLabel(AppLocalizations l10n, BudgetPeriod period) =>
      switch (period) {
        BudgetPeriod.weekly => l10n.budgetPeriodWeekly,
        BudgetPeriod.biweekly => l10n.budgetPeriodBiweekly,
        BudgetPeriod.monthly => l10n.budgetPeriodMonthly,
        BudgetPeriod.yearly => l10n.budgetPeriodYearly,
        BudgetPeriod.custom => l10n.budgetFormRepeatOneOff,
      };
}
