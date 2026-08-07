import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/entities/budget_period_window.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/presentation/utils/budget_format.dart';
import '../../domain/entities/month_spending.dart';
import 'home_hero_budget_progress.dart';
import 'month_selector_chip.dart';

/// The compact hero (HU-03): the spent total, and one of three states below
/// the amount — a budget progress bar, an invitation to budget, or "aún no
/// hay gastos". [monthLabel] and its "Gastado en <mes>" caption, plus
/// [MonthSelectorChip] (HU-04), only apply without a featured budget
/// (criterion 5): once one exists, the header row becomes
/// [HeroPeriodStepper] instead, navigating the budget's own period window
/// rather than a calendar month (HU-05).
///
/// It never invents a spending cap: without a budget the app knows no limit,
/// so instead of a fake progress bar it nudges the budgeting habit. With a
/// qualifying budget (`aOhoY`), [budgetProgress] drives a real progress bar
/// instead.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.spending,
    required this.monthLabel,
    required this.onCreateBudget,
    this.budgetProgress,
    this.onOpenBudget,
    this.onPreviousPeriod,
    this.onNextPeriod,
    this.onOpenMonthPicker,
    super.key,
  });

  final MonthSpending spending;

  /// The featured budget's progress for the period the stepper is currently
  /// showing (HU-03/HU-05, `aOhoY`), or `null` when none is featured — see
  /// `WatchFeaturedBudgetProgress`. Its `window` drives [HeroPeriodStepper]'s
  /// label and chevrons.
  final BudgetWithProgress? budgetProgress;

  /// The visible calendar month, already localized (e.g. "julio") — used for
  /// both the "Gastado en <mes>" caption and [MonthSelectorChip]'s own label
  /// when [budgetProgress] is `null` (criterion 5's fallback, HU-04).
  final String monthLabel;

  final VoidCallback onCreateBudget;

  /// Tapping the hero navigates to the featured budget's detail (criterion
  /// 6). Only meaningful (and only wired by the caller) when [budgetProgress]
  /// is not `null`.
  final VoidCallback? onOpenBudget;

  /// HU-05: steps [budgetProgress]'s window back/forward. Only called by
  /// [HeroPeriodStepper]'s chevrons, which already gate on
  /// `window.hasPrevious`/`hasNext`.
  final VoidCallback? onPreviousPeriod;
  final VoidCallback? onNextPeriod;

  /// HU-04: opens the month picker sheet. Only wired (and only rendered, via
  /// [MonthSelectorChip]) when [budgetProgress] is `null` — with a featured
  /// budget the same spot navigates its period window instead.
  final VoidCallback? onOpenMonthPicker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = budgetProgress;
    // With a featured budget, the amount must reflect ITS window (which can
    // be anchored on any day, e.g. "27 jul – 26 ago"), never the calendar
    // month total `spending` carries — that one only applies to the
    // no-budget-featured fallback caption/state below.
    final amount = const MoneyFormatter().formatSymbol(
      progress != null
          ? progress.progress.spentMinor
          : spending.displayTotalMinor,
      currencyCode: progress != null
          ? progress.budget.currency
          : spending.displayCurrency,
    );

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryDeep, colors.primary],
        ),
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Without a featured budget, the fallback caption ("Gastado en
          // <mes>") names the month above the amount, and `HC Month`
          // (`A9v7s`) shares the row so the user can still navigate months
          // (HU-04) — restored after the period-stepper redesign, which only
          // ever replaces this row when a budget IS featured.
          if (progress == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.homeSpentInMonth(monthLabel),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onOpenMonthPicker case final onOpenMonthPicker?) ...[
                  const SizedBox(width: 8),
                  MonthSelectorChip(
                    label: monthLabel,
                    onTap: onOpenMonthPicker,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            // "Gastado en <presupuesto>" kicker (xBv3N `zoZcf`): with a
            // budget featured, the stepper takes the caption's old spot
            // below the amount instead (criterion 3), so the amount needs
            // its own short label resolving "¿es gasto o saldo?" right
            // above it — and, per the discoverability fix
            // (`pages/presupuestos.md` § "Discoverability"), naming WHICH
            // budget it is, instead of a plain "Gastado" that left the user
            // guessing what fed the hero.
            Text(
              l10n.homeHeroSpentInFeaturedBudget(progress.budget.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            HeroPeriodStepper(
              budget: progress.budget,
              window: progress.window,
              onPrevious: onPreviousPeriod ?? () {},
              onNext: onNextPeriod ?? () {},
            ),
          ],
          const SizedBox(height: 10),
          if (progress != null)
            HomeHeroBudgetProgress(
              progress: progress.progress,
              currency: progress.budget.currency,
            )
          else if (spending.hasExpenses)
            BudgetInvitationLink(onTap: onCreateBudget)
          else
            Text(
              l10n.homeNoSpendingYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );

    if (progress == null) {
      return card;
    }
    // Criterion 6: tapping the hero opens the featured budget's own detail —
    // never a movements list. `Material` + `InkWell` wrap the gradient
    // container from the outside so the ripple draws over it without hiding
    // the gradient underneath.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      child: InkWell(
        onTap: onOpenBudget,
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
        child: card,
      ),
    );
  }
}

/// The hero's period stepper (HU-05, `xBv3N` `diOFU`), replacing the old
/// calendar-month chip once a budget is featured. It sits directly on the
/// gradient — no pill/card of its own (the "isla" `$surface` container was
/// explicitly reviewed and dropped, `p4nEEU`). Two 44pt `$surface` chevron
/// circles (same shape as the header's bell button, `PageHeaderCircleButton`)
/// flank the budget's real period range and status
/// (`BudgetFormat.stepperRange`/`stepperState`, e.g. "21 jul – 20 ago ·
/// vigente") — never a calendar month name. Chevrons dim to 40% at the
/// budget's bounds, same convention as the detail screen's
/// `PeriodStepperPill`.
class HeroPeriodStepper extends StatelessWidget {
  const HeroPeriodStepper({
    required this.budget,
    required this.window,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final Budget budget;
  final BudgetPeriodWindow window;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Row(
      children: [
        HeroPeriodChevron(
          icon: LucideIcons.chevronLeft,
          tooltip: l10n.budgetPeriodPreviousTooltip,
          onPressed: window.hasPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  BudgetFormat.stepperRange(l10n, budget, window, locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  BudgetFormat.stepperState(l10n, budget, window, locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        HeroPeriodChevron(
          icon: LucideIcons.chevronRight,
          tooltip: l10n.budgetPeriodNextTooltip,
          onPressed: window.hasNext ? onNext : null,
        ),
      ],
    );
  }
}

/// One chevron of [HeroPeriodStepper]: the shared 44pt circle button, solid
/// `$surface` fill with a `$text-primary` icon (`xBv3N` `a09pi`/`A11npZ`) —
/// same treatment as the Home header's bell button — dimmed to 40% when there
/// is no window to step to, same rule as the detail screen's
/// `PeriodStepperChevron`.
class HeroPeriodChevron extends StatelessWidget {
  const HeroPeriodChevron({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = PageHeaderCircleButton(
      icon: icon,
      background: colors.surface,
      foreground: colors.textPrimary,
      tooltip: tooltip,
      onPressed: onPressed,
    );
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      // Disabled means "no window to step to" — a no-op `InkWell` (see
      // `PageHeaderCircleButton`) does not claim the tap, so without this it
      // falls through the gesture arena to the whole-card `InkWell` around
      // `HomeHeroCard` and wrongly opens the featured budget's detail. An
      // opaque `GestureDetector` with a no-op `onTap` absorbs it instead —
      // the chevron does nothing, exactly as a disabled control should.
      child: onPressed == null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: button,
            )
          : button,
    );
  }
}

class BudgetInvitationLink extends StatelessWidget {
  const BudgetInvitationLink({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeBudgetInvitation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.arrowRight, size: 18, color: colors.onPrimary),
          ],
        ),
      ),
    );
  }
}
