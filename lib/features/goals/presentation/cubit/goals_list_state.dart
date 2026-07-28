import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_list_momentum.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../../domain/services/goal_list_momentum_calculator.dart';

/// The three states the goals list renders (HU-11).
enum GoalsListStatus { loading, ready, failure }

class GoalsListState extends Equatable {
  const GoalsListState({
    this.status = GoalsListStatus.loading,
    this.goals = const [],
    this.failure,
  });

  final GoalsListStatus status;

  /// Active goals with their derived progress, already ordered by
  /// `WatchGoals.sorted` (nearest `targetDate` first, then no date, then
  /// completed-not-archived last).
  final List<GoalWithProgress> goals;

  final Failure? failure;

  bool get isEmpty => status == GoalsListStatus.ready && goals.isEmpty;

  /// HU-12: the coherence signals of every goal that carries one, one per
  /// account (never duplicated — `goals` already carries one signal per goal
  /// linked to an over-assigned account, so this dedupes by `accountId`).
  List<GoalCoherenceSignal> get coherenceSignals {
    final byAccount = <String, GoalCoherenceSignal>{};
    for (final entry in goals) {
      final signal = entry.coherence;
      if (signal != null) {
        byAccount[signal.accountId] = signal;
      }
    }
    return byAccount.values.toList();
  }

  /// HU-15: the list header's cross-goal momentum signal, aggregated from
  /// every goal's own `GoalMomentum` — never computed when the list is
  /// still loading/empty (the page only reads this once `goals` is ready and
  /// non-empty).
  GoalListMomentum get momentum => GoalListMomentumCalculator.calculate(goals);

  GoalsListState copyWith({
    GoalsListStatus? status,
    List<GoalWithProgress>? goals,
    Failure? failure,
  }) =>
      GoalsListState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        // A fresh state carrying data clears the failure by not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [status, goals, failure];
}
