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

  /// The form's date rows spell the month out — locale-aware, so es renders
  /// "21 de julio de 2026" and en "July 21, 2026" (`a3gGPM/cb5On`). The compact
  /// [dayMonth] is for the dense list/detail meta lines, not for a field the
  /// user is about to change. [locale] comes from
  /// `Localizations.localeOf(context).toString()`.
  static String longDate(DateTime date, String locale) =>
      DateFormat.yMMMMd(locale).format(date);

  /// Compact day + short month ("30 jun" / "Jun 30"), locale-aware, as the
  /// history's "Cerrado <fecha>" (`qlbT0`) and the meta lines spell it.
  static String dayMonth(DateTime date, String locale) =>
      DateFormat.MMMd(locale).format(date);

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
    String locale,
  ) =>
      budget.isOneOff
          ? l10n.budgetEndsOn(dayMonth(window.lastDay, locale))
          : l10n.budgetResetsOn(dayMonth(window.endExclusive, locale));

  /// The explicit cycle range for the period stepper, e.g. "1–31 jul" or
  /// "21 jul – 20 ago".
  static String rangeLabel(BudgetPeriodWindow window, String locale) {
    final start = window.start;
    final last = window.lastDay;
    if (start.year == last.year && start.month == last.month) {
      return '${start.day}–${dayMonth(last, locale)}';
    }
    return '${dayMonth(start, locale)} – ${dayMonth(last, locale)}';
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

  /// The hero's second caption line for what is "programado" (HU-12): `null`
  /// when nothing is scheduled in the window. Reads as a projection, never
  /// a fact already true — "excedería", never "excede" (MASTER.md).
  static String? scheduledCaption(
    AppLocalizations l10n,
    BudgetProgress progress,
    String currency,
  ) {
    if (progress.scheduledMinor <= 0) {
      return null;
    }
    const money = MoneyFormatter();
    final scheduledAmount =
        money.formatSymbol(progress.scheduledMinor, currencyCode: currency);
    if (progress.isScheduledOverspendRisk) {
      final overage = money.formatSymbol(
        progress.scheduledOverageMinor,
        currencyCode: currency,
      );
      return l10n.budgetScheduledCaptionRisk(scheduledAmount, overage);
    }
    return l10n.budgetScheduledCaption(
        scheduledAmount, progress.committedPercent);
  }

  /// The "Programado" entry card's sub line (HU-12): the risk's overage takes
  /// over the plain "N pagos próximos" count, same reasoning as
  /// [scheduledCaption].
  static String scheduledEntrySub(
    AppLocalizations l10n,
    BudgetProgress progress,
    String currency,
    int count,
  ) {
    if (progress.isScheduledOverspendRisk) {
      const money = MoneyFormatter();
      return l10n.budgetScheduledEntrySubRisk(
        money.formatSymbol(progress.scheduledOverageMinor,
            currencyCode: currency),
      );
    }
    return l10n.budgetScheduledEntrySub(count);
  }

  /// The stepper's leading, bold half. A recurring budget steps through cycles
  /// so it names the range ("1–31 jul"); a one-off has a single window, so
  /// naming a range would suggest a navigation that does not exist — `QLn6w`
  /// reads "Ventana única" instead.
  static String stepperRange(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
    String locale,
  ) =>
      budget.isOneOff ? l10n.budgetOneOffWindow : rangeLabel(window, locale);

  /// The stepper's trailing, secondary half ("· vigente", "· termina el
  /// 24 dic"). The bullet belongs to this text node in `NloPT/e6kYhx`.
  static String stepperState(
    AppLocalizations l10n,
    Budget budget,
    BudgetPeriodWindow window,
    String locale,
  ) =>
      budget.isOneOff
          ? '· ${l10n.budgetEndsOn(dayMonth(window.lastDay, locale))}'
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
