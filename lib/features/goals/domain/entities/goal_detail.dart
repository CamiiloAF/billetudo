import 'package:equatable/equatable.dart';

import 'goal_contribution.dart';
import 'goal_momentum.dart';
import 'goal_projection.dart';
import 'goal_with_progress.dart';

/// The full detail of one goal (HU-05/HU-06/HU-07/HU-12/HU-15): its progress,
/// its projection, its momentum and its movement history, newest first.
class GoalDetail extends Equatable {
  const GoalDetail({
    required this.progress,
    required this.projection,
    required this.momentum,
    required this.history,
  });

  final GoalWithProgress progress;
  final GoalProjection projection;
  final GoalMomentum momentum;

  /// Every non-hidden movement, newest first.
  final List<GoalContribution> history;

  @override
  List<Object?> get props => [progress, projection, momentum, history];
}
