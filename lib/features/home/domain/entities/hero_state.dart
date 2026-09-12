import '../../../budgets/domain/entities/budget_with_progress.dart';

/// One of the 7 business states Home's compact hero renders
/// (`design-system/billetudo/pages/inicio.md` § "Hero se comprime..."),
/// resolved from a [BudgetWithProgress]'s `progress` (or its absence) plus
/// whether the user has ever created a budget at all.
///
/// [healthy] and [nearLimit] render identically today (both stay
/// `$on-primary`, untinted — "sin semáforo por cercanía" is the whole point
/// of the color model) and only [atLimit] onward changes look. They are kept
/// as separate members anyway because the design spec names 7 distinct
/// business states, not because the color model needs the split — a future
/// change to the "near the limit" copy/threshold should not require
/// reshaping this enum.
enum HomeHeroState {
  /// Spending comfortably inside the budget.
  healthy,

  /// Close to the limit ([HomeHeroStateResolver.nearLimitThresholdPercent]%
  /// or more spent), still untinted — same visual as [healthy].
  nearLimit,

  /// Exactly 100% spent: the limit was reached (a fact), not yet a real
  /// overspend. Only the bar tints, the kicker/amount stay unchanged.
  atLimit,

  /// Real spend has not crossed the budget, but projected scheduled-payment
  /// spend would (`BudgetProgress.isScheduledOverspendRisk`).
  scheduledOverspendRisk,

  /// Real spend has crossed the budget (`BudgetProgress.isOverspent`).
  overspent,

  /// The user has never created a single budget (active or not).
  noBudgetEverCreated,

  /// The user has one or more budgets, but none is featured on Home right
  /// now (nothing qualifies automatically and nothing was picked manually).
  noBudgetFeatured,
}

/// Pure resolution of [HomeHeroState] — no Flutter, no repository access, so
/// it is unit-testable on its own (same convention as `HomeSnapshot.from`).
abstract final class HomeHeroStateResolver {
  /// The percent threshold (inclusive) at which a healthy budget's state
  /// becomes [HomeHeroState.nearLimit] instead of [HomeHeroState.healthy].
  /// Both render the same today (see [HomeHeroState] docs); this only
  /// changes which named state a caller/test sees.
  static const int nearLimitThresholdPercent = 90;

  /// Resolves the hero's state. [featuredBudget] is the currently featured
  /// budget's progress (`WatchFeaturedBudgetProgress`), `null` when nothing
  /// is featured. [hasAnyBudget] disambiguates that `null` case between
  /// "never created one" and "has some, none featured" — see
  /// `WatchHasAnyBudget`.
  static HomeHeroState resolve({
    required BudgetWithProgress? featuredBudget,
    required bool hasAnyBudget,
  }) {
    if (featuredBudget == null) {
      return hasAnyBudget
          ? HomeHeroState.noBudgetFeatured
          : HomeHeroState.noBudgetEverCreated;
    }

    final progress = featuredBudget.progress;
    if (progress.isOverspent) {
      return HomeHeroState.overspent;
    }
    if (progress.isScheduledOverspendRisk) {
      return HomeHeroState.scheduledOverspendRisk;
    }
    if (progress.percent >= 100) {
      return HomeHeroState.atLimit;
    }
    if (progress.percent >= nearLimitThresholdPercent) {
      return HomeHeroState.nearLimit;
    }
    return HomeHeroState.healthy;
  }
}
