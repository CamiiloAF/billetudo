import 'package:equatable/equatable.dart';

import 'home_ai_insight.dart';

/// Per-[HomeAiInsightType] "shown"/"dismissed" bookkeeping, resolved by
/// `HomeInsightEventRepository` from `HomeInsightEvents`
/// (`core/database/app_database.dart`) and consumed by `WatchHomeAiInsight`
/// to decide which candidate is allowed to surface right now.
///
/// `HomeAiInsightType.createBudget` never appears in either map: it is a
/// forced state, not a dismissible/coolable insight (see the type's own doc
/// comment) — `WatchHomeAiInsight` never even asks about it.
class HomeInsightEventSnapshot extends Equatable {
  const HomeInsightEventSnapshot({
    this.dismissedAt = const {},
    this.lastShownAt = const {},
  });

  /// The most recent "Ahora no" per type. Absent (not `null`-valued) when a
  /// type has never been dismissed.
  final Map<HomeAiInsightType, DateTime> dismissedAt;

  /// The most recent time the card actually showed a type. Absent when a
  /// type has never been shown.
  final Map<HomeAiInsightType, DateTime> lastShownAt;

  @override
  List<Object?> get props => [dismissedAt, lastShownAt];
}
