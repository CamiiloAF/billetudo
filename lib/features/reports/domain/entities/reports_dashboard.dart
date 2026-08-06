import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../goals/domain/entities/goal_with_progress.dart';

/// The HU-04 "Resumen" tab: a pure presentation bundle of what `budgets` and
/// `goals` already compute. This entity does no math of its own — it exists
/// only so `WatchReportsDashboard` has something to emit; every figure inside
/// [budgets]/[goals] comes verbatim from `GetActiveBudgets`/`WatchGoals`.
class ReportsDashboard extends Equatable {
  const ReportsDashboard({required this.budgets, required this.goals});

  final List<BudgetWithProgress> budgets;
  final List<GoalWithProgress> goals;

  /// HU-06 "Resumen vacío": no active budgets and no active goals.
  bool get isEmpty => budgets.isEmpty && goals.isEmpty;

  @override
  List<Object?> get props => [budgets, goals];
}
