import 'package:equatable/equatable.dart';

import 'budget_activity_item.dart';
import 'budget_period_window.dart';
import 'budget_progress.dart';

/// A read-only view of one period of a budget (HU-05): the window, its progress
/// and the activity that fed it (matched expenses, newest first). This is what
/// the detail screen renders for the currently selected period.
class BudgetPeriodView extends Equatable {
  const BudgetPeriodView({
    required this.window,
    required this.progress,
    required this.activity,
  });

  final BudgetPeriodWindow window;
  final BudgetProgress progress;

  /// Matched expenses of the window, newest first.
  final List<BudgetActivityItem> activity;

  @override
  List<Object?> get props => [window, progress, activity];
}
