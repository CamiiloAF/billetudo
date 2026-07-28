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
    this.filterAccountId,
    this.filterAccountName,
  });

  final GoalsListStatus status;

  /// Active goals with their derived progress, already ordered by
  /// `WatchGoals.sorted` (nearest `targetDate` first, then no date, then
  /// completed-not-archived last).
  final List<GoalWithProgress> goals;

  final Failure? failure;

  /// HU-12's "lista filtrada por cuenta" (`qFX42`): set by
  /// `GoalsListCubit.filterByAccount`, tapped from the coherence banner's
  /// "Ver las metas de esta cuenta" link. `null` = no filter (the default
  /// list). Both are set/cleared together — never one without the other.
  final String? filterAccountId;
  final String? filterAccountName;

  bool get isEmpty => status == GoalsListStatus.ready && goals.isEmpty;

  bool get isFiltered => filterAccountId != null;

  /// The goals actually rendered: every active goal when there is no filter,
  /// or only those linked to [filterAccountId] otherwise.
  List<GoalWithProgress> get visibleGoals {
    final accountId = filterAccountId;
    if (accountId == null) {
      return goals;
    }
    return goals.where((entry) => entry.goal.accountId == accountId).toList();
  }

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

  /// The single coherence signal still relevant while [isFiltered] — `qFX42`
  /// keeps showing the same informative row underneath the filter chip, when
  /// the filtered account still overshoots.
  GoalCoherenceSignal? get filteredCoherenceSignal {
    final accountId = filterAccountId;
    if (accountId == null) {
      return null;
    }
    for (final signal in coherenceSignals) {
      if (signal.accountId == accountId) {
        return signal;
      }
    }
    return null;
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
    bool clearFilter = false,
    ({String id, String name})? filter,
  }) =>
      GoalsListState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        // A fresh state carrying data clears the failure by not passing one.
        failure: failure,
        filterAccountId:
            clearFilter ? null : (filter?.id ?? filterAccountId),
        filterAccountName:
            clearFilter ? null : (filter?.name ?? filterAccountName),
      );

  @override
  List<Object?> get props =>
      [status, goals, failure, filterAccountId, filterAccountName];
}
