import 'package:equatable/equatable.dart';

import 'budget_activity_item.dart';
import 'budget_period_window.dart';
import 'budget_progress.dart';
import 'budget_scheduled_item.dart';

/// A read-only view of one period of a budget (HU-05): the window, its progress
/// and the activity that fed it (matched expenses, newest first). This is what
/// the detail screen renders for the currently selected period.
class BudgetPeriodView extends Equatable {
  const BudgetPeriodView({
    required this.window,
    required this.progress,
    required this.activity,
    this.scheduledItems = const [],
  });

  final BudgetPeriodWindow window;
  final BudgetProgress progress;

  /// Matched expenses of the window, newest first.
  final List<BudgetActivityItem> activity;

  /// What composes [BudgetProgress.scheduledMinor] (HU-12): projected and
  /// pending occurrences, soonest first. Empty for a past window.
  final List<BudgetScheduledItem> scheduledItems;

  @override
  List<Object?> get props => [window, progress, activity, scheduledItems];
}
