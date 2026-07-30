import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goals.dart';
import 'package:billetudo/features/reports/domain/entities/reports_dashboard.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_reports_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetActiveBudgets extends Mock implements GetActiveBudgets {}

class MockWatchGoals extends Mock implements WatchGoals {}

/// HU-04: `WatchReportsDashboard` does no math of its own, it only combines
/// `GetActiveBudgets` and `WatchGoals` verbatim (criterion 4).
void main() {
  late MockGetActiveBudgets getActiveBudgets;
  late MockWatchGoals watchGoals;
  late WatchReportsDashboard usecase;

  setUp(() {
    getActiveBudgets = MockGetActiveBudgets();
    watchGoals = MockWatchGoals();
    usecase = WatchReportsDashboard(getActiveBudgets, watchGoals);
  });

  test('emits once both sources have emitted, combining their lists',
      () async {
    final budgetsController =
        StreamController<Result<List<BudgetWithProgress>>>();
    final goalsController = StreamController<Result<List<GoalWithProgress>>>();
    when(() => getActiveBudgets()).thenAnswer((_) => budgetsController.stream);
    when(() => watchGoals()).thenAnswer((_) => goalsController.stream);

    final emissions = <Result<ReportsDashboard>>[];
    final subscription = usecase().listen(emissions.add);

    budgetsController.add(const Right(<BudgetWithProgress>[]));
    await Future<void>.delayed(Duration.zero);
    expect(emissions, isEmpty); // still waiting on goals

    goalsController.add(const Right(<GoalWithProgress>[]));
    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(1));
    final dashboard = emissions.single.getRight().toNullable()!;
    expect(dashboard.isEmpty, isTrue);

    await subscription.cancel();
    await budgetsController.close();
    await goalsController.close();
  });

  test('propagates a Left from either source', () async {
    const failure = DatabaseFailure('boom');
    when(() => getActiveBudgets()).thenAnswer(
      (_) => Stream.value(const Left(failure)),
    );
    when(() => watchGoals()).thenAnswer(
      (_) => Stream.value(const Right(<GoalWithProgress>[])),
    );

    final result = await usecase().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
