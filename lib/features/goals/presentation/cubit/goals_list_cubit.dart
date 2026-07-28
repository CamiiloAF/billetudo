import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../../domain/usecases/watch_goals.dart';
import 'goals_list_state.dart';

/// Drives the goals list (HU-11) and its momentum/coherence signals. Talks
/// only to [WatchGoals] — the ordering (nearest date first, then no date,
/// then completed) and the HU-12 coherence signal already live in the
/// domain, so this cubit only turns the stream into UI state.
@injectable
class GoalsListCubit extends Cubit<GoalsListState> {
  GoalsListCubit(this._watchGoals) : super(const GoalsListState());

  final WatchGoals _watchGoals;

  StreamSubscription<Result<List<GoalWithProgress>>>? _subscription;

  /// Subscribes to the stream. Safe to call again to retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(const GoalsListState());
    _subscription = _watchGoals().listen(_onGoals);
  }

  void _onGoals(Result<List<GoalWithProgress>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: GoalsListStatus.failure,
          failure: failure,
        ),
        (goals) => state.copyWith(
          status: GoalsListStatus.ready,
          goals: goals,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
