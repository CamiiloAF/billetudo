import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/entities/budget_period_window.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/presentation/utils/budget_format.dart';
import '../../domain/entities/hero_state.dart';
import '../../domain/entities/month_spending.dart';
import 'home_hero_budget_progress.dart';
import 'month_selector_chip.dart';
import 'risk_note.dart';

/// The Home's compact multi-state hero (`Hero Compact · Presupuesto (D)`,
/// `xRSdl`, `design-system/billetudo/pages/inicio.md` § "Hero compacto"): the
/// same 7 business states of [HomeHeroState] resolved onto one component via
/// overrides, never restructured per state.
///
/// The kicker + big amount are a fixed anchor: whenever there is a remaining
/// balance (every state but [HomeHeroState.overspent]), they always answer
/// "Te quedan $X" — any extra signal (the projected-overspend risk) is added
/// information on its own line ([RiskNote]), never a replacement. Only real
/// overspend swaps the pair for "Excedido por $X".
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.heroState,
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

  final HomeHeroState heroState;

  final MonthSpending spending;

  /// The featured budget's progress for the period the stepper is currently
  /// showing, or `null` for [HomeHeroState.noBudgetEverCreated] /
  /// [HomeHeroState.noBudgetFeatured].
  final BudgetWithProgress? budgetProgress;

  /// The visible calendar month, already localized — used for both the
  /// "Gastado en <mes>" caption and [MonthSelectorChip]'s label in the two
  /// no-budget states.
  final String monthLabel;

  final VoidCallback onCreateBudget;

  /// Tapping the hero navigates to the featured budget's detail. Only
  /// meaningful (and only wired by the caller) when [budgetProgress] is not
  /// `null`.
  final VoidCallback? onOpenBudget;

  final VoidCallback? onPreviousPeriod;
  final VoidCallback? onNextPeriod;

  /// Opens the month picker sheet. Only wired (and only rendered) in the two
  /// no-budget states.
  final VoidCallback? onOpenMonthPicker;

  @override
  Widget build(BuildContext context) {
    final progress = budgetProgress;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primaryDeep,
            context.colors.primary,
            context.colors.primary,
          ],
          stops: const [0, 0.65, 1],
        ),
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      ),
      child: progress != null
          ? FeaturedBudgetHero(
              heroState: heroState,
              progress: progress,
              onPreviousPeriod: onPreviousPeriod,
              onNextPeriod: onNextPeriod,
            )
          : NoBudgetHero(
              heroState: heroState,
              spending: spending,
              monthLabel: monthLabel,
              onCreateBudget: onCreateBudget,
              onOpenMonthPicker: onOpenMonthPicker,
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

/// The 5 "con presupuesto" states: sano, al límite, límite exacto, riesgo de
/// sobregiro proyectado y sobregasto real.
class FeaturedBudgetHero extends StatelessWidget {
  const FeaturedBudgetHero({
    required this.heroState,
    required this.progress,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    super.key,
  });

  final HomeHeroState heroState;
  final BudgetWithProgress progress;
  final VoidCallback? onPreviousPeriod;
  final VoidCallback? onNextPeriod;

  bool get _isOverspent => heroState == HomeHeroState.overspent;
  bool get _isAtLimitOrOverspent =>
      heroState == HomeHeroState.atLimit || _isOverspent;
  bool get _isRisk => heroState == HomeHeroState.scheduledOverspendRisk;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final budget = progress.budget;
    final budgetProgress = progress.progress;
    final currency = budget.currency;

    final spentColor =
        _isAtLimitOrOverspent ? colors.onPrimaryAlert : colors.onPrimary;
    final kicker = _isOverspent
        ? l10n.homeHeroOverspentKicker
        : l10n.homeHeroRemainingKicker;
    final amountMinor = _isOverspent
        ? -budgetProgress.remainingMinor
        : budgetProgress.remainingMinor;
    final amountText = money.formatSymbol(amountMinor, currencyCode: currency);
    final baseSize = _isOverspent ? 32.0 : 30.0;
    final amountSize = amountText.length > 10 ? 26.0 : baseSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                budget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PeriodPill(
              window: progress.window,
              budget: budget,
              onPrevious: onPreviousPeriod,
              onNext: onNextPeriod,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kicker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isOverspent) ...[
                        Icon(
                          LucideIcons.circleMinus,
                          size: amountSize * 0.55,
                          color: colors.onPrimaryAlert,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          amountText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: _isOverspent
                                ? colors.onPrimaryAlert
                                : colors.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: amountSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homeHeroBudgetProgress(
                    budgetProgress.percent,
                    money.formatSymbol(
                      budgetProgress.amountMinor,
                      currencyCode: currency,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  l10n.homeHeroMetaDaysLeft(budgetProgress.daysLeft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        HomeHeroBudgetProgress(
          progress: budgetProgress,
          spentColor: spentColor,
        ),
        if (_isRisk) ...[
          const SizedBox(height: 8),
          RiskNote(
            text: l10n.homeHeroRiskNote(
              money.formatSymbol(
                budgetProgress.scheduledOverageMinor,
                currencyCode: currency,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The hero's period stepper when a budget is featured (`Period Pill`,
/// `v1YJG`, `design-system/billetudo/pages/inicio.md` § "Hero compacto"):
/// two 44x44 chevron hit targets flanking the budget's real window range
/// (never a calendar-month name).
///
/// The whole pill absorbs its own tap gesture and never lets it fall through
/// to the hero's own `InkWell` (`HomeHeroCard`'s `onOpenBudget`): tapping the
/// range label itself does nothing (it is the control's own caption, not a
/// button), and a disabled chevron swallows the tap instead of leaking it to
/// the card underneath.
class PeriodPill extends StatelessWidget {
  const PeriodPill({
    required this.window,
    required this.budget,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final BudgetPeriodWindow window;
  final Budget budget;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final label = BudgetFormat.stepperRange(l10n, budget, window, locale);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: colors.monthChipBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PillChevron(
              icon: LucideIcons.chevronLeft,
              onPressed: window.hasPrevious ? onPrevious : null,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            PillChevron(
              icon: LucideIcons.chevronRight,
              onPressed: window.hasNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// One 44x44 hit target of [PeriodPill]. A `null` [onPressed] renders the
/// chevron dimmed and ignores pointer events entirely — the tap then falls
/// through to [PeriodPill]'s own absorbing `GestureDetector`, never to the
/// hero underneath.
class PillChevron extends StatelessWidget {
  const PillChevron({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: colors.onPrimary),
      ),
    );

    return !enabled
        ? IgnorePointer(
            child: Opacity(opacity: 0.4, child: button),
          )
        : button;
  }
}

/// The two "sin presupuesto destacado" states: never created one, or has one
/// (or more) but none is featured right now. Same layout for both — only the
/// invite's note text differs.
class NoBudgetHero extends StatelessWidget {
  const NoBudgetHero({
    required this.heroState,
    required this.spending,
    required this.monthLabel,
    required this.onCreateBudget,
    this.onOpenMonthPicker,
    super.key,
  });

  final HomeHeroState heroState;
  final MonthSpending spending;
  final String monthLabel;
  final VoidCallback onCreateBudget;
  final VoidCallback? onOpenMonthPicker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amount = const MoneyFormatter().formatSymbol(
      spending.displayTotalMinor,
      currencyCode: spending.displayCurrency,
    );
    final note = heroState == HomeHeroState.noBudgetEverCreated
        ? l10n.homeHeroNoBudgetEverCreatedNote
        : l10n.homeHeroNoBudgetFeaturedNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              MonthSelectorChip(label: monthLabel, onTap: onOpenMonthPicker),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displaySmall?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onCreateBudget,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.monthChipBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.arrowRight, size: 16, color: colors.onPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
