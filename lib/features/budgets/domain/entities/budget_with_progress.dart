import 'package:equatable/equatable.dart';

import 'budget.dart';
import 'budget_period_window.dart';
import 'budget_progress.dart';
import 'budget_scope.dart';

/// A budget together with everything the list row needs: its scope (for the
/// short scope label and the stranded warning), the current period window (for
/// the temporal anchor) and its progress (HU-04).
class BudgetWithProgress extends Equatable {
  const BudgetWithProgress({
    required this.budget,
    required this.scope,
    required this.window,
    required this.progress,
  });

  final Budget budget;
  final BudgetScope scope;
  final BudgetPeriodWindow window;
  final BudgetProgress progress;

  @override
  List<Object?> get props => [budget, scope, window, progress];
}
