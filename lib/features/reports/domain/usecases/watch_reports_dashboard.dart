import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../../../goals/domain/entities/goal_with_progress.dart';
import '../../../goals/domain/usecases/watch_goals.dart';
import '../entities/reports_dashboard.dart';

/// HU-04: the "Resumen" tab. Composes the two use cases Presupuestos/Metas
/// already expose — `GetActiveBudgets` and `WatchGoals` — into a single
/// stream. Deliberately **no** progress math lives here (criterion 4 of this
/// entrega): both figures are read verbatim from their own feature so this
/// view can never drift from the screens it summarizes.
@injectable
class WatchReportsDashboard {
  const WatchReportsDashboard(this._getActiveBudgets, this._watchGoals);

  final GetActiveBudgets _getActiveBudgets;
  final WatchGoals _watchGoals;

  Stream<Result<ReportsDashboard>> call() =>
      _combineLatest(_getActiveBudgets(), _watchGoals());

  /// Minimal combineLatest for exactly 2 sources — the project has no rxdart
  /// dependency, and pulling one in for a single call site is not worth it.
  /// Emits once both sources have produced at least one value, then again on
  /// every subsequent emission of either.
  Stream<Result<ReportsDashboard>> _combineLatest(
    Stream<Result<List<BudgetWithProgress>>> budgets,
    Stream<Result<List<GoalWithProgress>>> goals,
  ) {
    late final StreamController<Result<ReportsDashboard>> controller;
    StreamSubscription<Result<List<BudgetWithProgress>>>? budgetsSub;
    StreamSubscription<Result<List<GoalWithProgress>>>? goalsSub;
    Result<List<BudgetWithProgress>>? latestBudgets;
    Result<List<GoalWithProgress>>? latestGoals;
    var openSources = 2;

    void closeIfDone() {
      openSources--;
      if (openSources == 0) {
        unawaited(controller.close());
      }
    }

    void emit() {
      final budgetsResult = latestBudgets;
      final goalsResult = latestGoals;
      if (budgetsResult == null || goalsResult == null) return;
      controller.add(
        budgetsResult.flatMap(
          (budgetList) => goalsResult.map(
            (goalList) =>
                ReportsDashboard(budgets: budgetList, goals: goalList),
          ),
        ),
      );
    }

    controller = StreamController<Result<ReportsDashboard>>.broadcast(
      onListen: () {
        budgetsSub = budgets.listen(
          (event) {
            latestBudgets = event;
            emit();
          },
          onError: controller.addError,
          onDone: closeIfDone,
        );
        goalsSub = goals.listen(
          (event) {
            latestGoals = event;
            emit();
          },
          onError: controller.addError,
          onDone: closeIfDone,
        );
      },
      onCancel: () async {
        await budgetsSub?.cancel();
        await goalsSub?.cancel();
      },
    );
    return controller.stream;
  }
}
