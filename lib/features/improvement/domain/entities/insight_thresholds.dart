/// The hard significance thresholds every insight must clear before it is
/// allowed to exist, plus the frequency cap over the whole set.
///
/// These are not tuning knobs, they are the feature's safety rail. Without a
/// minimum of data and a minimum of relevance, an insight is either obvious
/// or wrong — and one obvious or wrong notice destroys more trust than a good
/// one builds. Notification fatigue is the classic failure mode here: the
/// first irrelevant notice trains the person to ignore every one after it.
abstract final class InsightThresholds {
  /// How far ahead an upcoming charge is worth mentioning. Beyond a week it
  /// is not news; it is the schedule the user already set.
  static const int upcomingChargeHorizonDays = 7;

  /// Amounts below this (in minor units) do not earn a notice: the attention
  /// it costs is worth more than the sum it names.
  static const int minimumAmountMinor = 1000;

  /// Only these goal thresholds are celebrated. 25% is deliberately excluded:
  /// too early to be an achievement, frequent enough to become noise.
  static const List<int> celebratedGoalPercents = <int>[50, 75, 100];

  /// How recent a milestone must be to still be worth surfacing. An
  /// achievement from last month is history, not news.
  static const int goalMilestoneFreshnessDays = 7;

  /// Ceiling on how many insights the surface may show at once — the
  /// frequency cap. A list of twelve notices is a list nobody reads.
  static const int maxInsights = 5;
}
