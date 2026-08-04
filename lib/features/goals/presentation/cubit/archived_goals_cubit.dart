import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../../domain/usecases/archive_goal.dart';
import '../../domain/usecases/watch_archived_goals.dart';
import 'archived_goals_state.dart';

/// Drives "Metas archivadas" (HU-09): the archived list plus the
/// desarchivar action, so a user can bring a paused goal back to the main
/// list without leaving this screen.
@injectable
class ArchivedGoalsCubit extends Cubit<ArchivedGoalsState> {
  ArchivedGoalsCubit(
    this._watchArchivedGoals,
    this._archiveGoal,
    this._watchAccounts,
  ) : super(const ArchivedGoalsState());

  final WatchArchivedGoals _watchArchivedGoals;
  final ArchiveGoal _archiveGoal;
  final WatchAccounts _watchAccounts;

  StreamSubscription<Result<List<GoalWithProgress>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const ArchivedGoalsState());
    final accountsResult = await _watchAccounts().first;
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        accounts: accountsResult.fold((_) => const [], (list) => list),
      ),
    );
    _subscription = _watchArchivedGoals().listen(_onGoals);
  }

  void _onGoals(Result<List<GoalWithProgress>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ArchivedGoalsStatus.failure,
          failure: failure,
        ),
        (goals) => state.copyWith(
          status: ArchivedGoalsStatus.ready,
          goals: goals,
        ),
      ),
    );
  }

  /// HU-09: desarchivar. The list refreshes on its own via the stream.
  Future<void> unarchive(String goalId) => _archiveGoal.unarchive(goalId);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
