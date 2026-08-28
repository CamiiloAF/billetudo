import 'package:equatable/equatable.dart';

/// Which family of insight the AI card (`ai_card.dart`) shows in its slot-2
/// "with insight" variant (`design-system/billetudo/pages/inicio.md` §
/// "Card de IA — chrome condicional").
///
/// Only carries the *kind* and the numbers behind it — never UI copy: text
/// lives in `AppLocalizations` (`avoid_hardcoded_ui_strings`), resolved by
/// the presentation layer from `type` plus the numeric fields below.
enum HomeAiInsightType {
  /// This month's spend compares meaningfully against the trailing 3-month
  /// average (needs at least 3 months of history to be trustworthy).
  spendingVsAverage,

  /// The featured budget's real spend has not crossed 100%, but projected
  /// scheduled-payment spend would — same condition as
  /// `HomeHeroState.scheduledOverspendRisk`.
  budgetProjectionRisk,

  /// The user has never created a budget (`HomeHeroState.noBudgetEverCreated`).
  /// Forced — never queued alongside the other two kinds, and never counted
  /// in [HomeAiInsight.queueLength] (criterion 10).
  createBudget,
}

/// One insight the AI card can show, plus how many more are waiting behind
/// it (the "1 de N" counter, shown only once [queueLength] is 2 or more).
class HomeAiInsight extends Equatable {
  const HomeAiInsight({
    required this.type,
    this.queuePosition = 1,
    this.queueLength = 1,
    this.percentDelta,
    this.overageMinor,
    this.currency,
  });

  /// Forced insight for `HomeHeroState.noBudgetEverCreated` — always alone
  /// in its queue (position 1 of 1), so the counter never renders for it.
  const HomeAiInsight.createBudget()
      : type = HomeAiInsightType.createBudget,
        queuePosition = 1,
        queueLength = 1,
        percentDelta = null,
        overageMinor = null,
        currency = null;

  final HomeAiInsightType type;

  /// 1-based position of this insight within the queue (the "1" in "1 de N").
  final int queuePosition;

  /// Total insights currently queued. The "1 de N" counter only shows when
  /// this is 2 or more (criterion 10: "SOLO cuando hay cola").
  final int queueLength;

  /// Set only for [HomeAiInsightType.spendingVsAverage]: how far this
  /// month's spend is from the trailing 3-month average, as a signed whole
  /// percent (positive = spending more than average).
  final int? percentDelta;

  /// Set only for [HomeAiInsightType.budgetProjectionRisk]: the projected
  /// overage in cents (`BudgetProgress.scheduledOverageMinor`).
  final int? overageMinor;

  /// The currency [overageMinor] (or the compared amounts behind
  /// [percentDelta]) is expressed in. `null` only for `createBudget`, which
  /// carries no amount.
  final String? currency;

  bool get hasQueue => queueLength >= 2;

  @override
  List<Object?> get props => [
        type,
        queuePosition,
        queueLength,
        percentDelta,
        overageMinor,
        currency,
      ];
}
