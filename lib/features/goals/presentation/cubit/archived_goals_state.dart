import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_with_progress.dart';

enum ArchivedGoalsStatus { loading, ready, failure }

/// HU-09: state for the "Metas archivadas" list.
class ArchivedGoalsState extends Equatable {
  const ArchivedGoalsState({
    this.status = ArchivedGoalsStatus.loading,
    this.goals = const [],
    this.failure,
  });

  final ArchivedGoalsStatus status;
  final List<GoalWithProgress> goals;
  final Failure? failure;

  bool get isEmpty => status == ArchivedGoalsStatus.ready && goals.isEmpty;

  ArchivedGoalsState copyWith({
    ArchivedGoalsStatus? status,
    List<GoalWithProgress>? goals,
    Failure? failure,
  }) =>
      ArchivedGoalsState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, goals, failure];
}
