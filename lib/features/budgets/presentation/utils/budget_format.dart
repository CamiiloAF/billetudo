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
  static final DateFormat _longDate = DateFormat("d 'de' MMMM y", 'es_CO');

  /// The form's date rows spell the month out ("21 de julio 2026",
  /// `a3gGPM/cb5On`) — the compact "21 jul" is for the dense list/detail meta
  /// lines, not for a field the user is about to change.
  static String longDate(DateTime date) => _longDate.format(date);

  /// Compact "d MMM" ("30 jun"), as the history's "Cerrado <fecha>" (`qlbT0`)
  /// and the meta lines spell it.
  static String dayMonth(DateTime date) => _dayMonth.format(date);

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

  /// The stepper's leading, bold half. A recurring budget steps through cycles
  /// so it names the range ("1–31 jul"); a one-off has a single window, so
  /// naming a range would suggest a navigation that does not exist — `QLn6w`
  /// reads "Ventana única" instead.
  static String stepperRange(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
  ) =>
      budget.isOneOff ? l10n.budgetOneOffWindow : rangeLabel(window);

  /// The stepper's trailing, secondary half ("· vigente", "· termina el
  /// 24 dic"). The bullet belongs to this text node in `NloPT/e6kYhx`.
  static String stepperState(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
  ) =>
      budget.isOneOff
          ? '· ${l10n.budgetEndsOn(_dayMonth.format(window.lastDay))}'
          : '· ${statusLabel(l10n, window.status)}';

  /// The hero's right caption: "Restan 18 días" while the cycle repeats,
  /// "Termina en 8 días" when the window is the budget's only one (`QLn6w`).
  ///
  /// `null` outside the running window: a period the stepper already labels
  /// "pasado" (or "próximo") has no days left to announce — counting down a
  /// closed cycle is simply false.
  static String? daysLeftCaption(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
    BudgetProgress progress,
  ) {
    if (!window.isCurrent) {
      return null;
    }
    return budget.isOneOff
        ? l10n.budgetEndsInDays(progress.daysLeft)
        : l10n.budgetDaysLeft(progress.daysLeft);
  }

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
