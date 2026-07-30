import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_point.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_series.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/entities/net_worth_point.dart';
import 'package:billetudo/features/reports/domain/entities/net_worth_series.dart';
import 'package:billetudo/features/reports/domain/entities/reports_dashboard.dart';

import '../../../budgets/domain/budget_fixtures.dart';
import '../../../goals/presentation/goals_presentation_fixtures.dart';

/// Fixtures for the Gráficas e informes golden suite. Dates are always fixed
/// (never `DateTime.now()`-relative) and, for the "with data"/"balance
/// negativo" cases, deliberately never land on the current calendar month —
/// `CashflowCardContent._isCurrentMonthNote` reads `DateTime.now()` directly,
/// so a range that could include "today" would make the golden
/// non-deterministic depending on when the suite runs.
final DateRange sixMonthRangeMonthly = DateRange(
  start: DateTime(2025, 1),
  endExclusive: DateTime(2025, 7),
  granularity: DateGranularity.monthly,
);

ChartHistoryBounds fullHistoryBounds({DateRange? requested}) {
  final range = requested ?? sixMonthRangeMonthly;
  return ChartHistoryBounds(
    earliestDataDate: DateTime(2023),
    requestedRange: range,
    effectiveRange: range,
    isClamped: false,
    isDailyGranularity: false,
  );
}

/// A clamped/short-history bounds: the user's data only goes back to
/// [earliestDataDate], well inside [requestedRange] — HU-06 "historial
/// insuficiente", daily granularity.
ChartHistoryBounds shortHistoryBounds() {
  final requested = sixMonthRangeMonthly;
  final effective = DateRange(
    start: DateTime(2025, 6, 20),
    endExclusive: DateTime(2025, 7),
    granularity: DateGranularity.daily,
  );
  return ChartHistoryBounds(
    earliestDataDate: DateTime(2025, 6, 20),
    requestedRange: requested,
    effectiveRange: effective,
    isClamped: true,
    isDailyGranularity: true,
  );
}

List<CashflowPoint> buildCashflowPoints({
  required List<(int income, int expense, int debtIncome, int debtExpense)>
  amounts,
  DateTime? start,
}) {
  final base = start ?? DateTime(2025, 1);
  return [
    for (var i = 0; i < amounts.length; i++)
      CashflowPoint(
        periodStart: DateTime(base.year, base.month + i),
        incomeMinor: amounts[i].$1,
        expenseMinor: amounts[i].$2,
        debtIncomeMinor: amounts[i].$3,
        debtExpenseMinor: amounts[i].$4,
      ),
  ];
}

/// 6 monthly buckets, net positive (income > expense every month).
CashflowSeries positiveCashflowSeries() => CashflowSeries(
  points: buildCashflowPoints(
    amounts: const [
      (3200000, 2100000, 0, 0),
      (3200000, 2400000, 0, 0),
      (3400000, 2000000, 150000, 100000),
      (3200000, 2600000, 0, 0),
      (3500000, 2200000, 0, 200000),
      (3300000, 2500000, 0, 0),
    ],
  ),
  includeDebtMovements: true,
  bounds: fullHistoryBounds(),
);

/// 6 monthly buckets, net negative — criterion 26 (never `$expense`,
/// two-frase explainer + "Ver en qué se fue" link).
CashflowSeries negativeCashflowSeries() => CashflowSeries(
  points: buildCashflowPoints(
    amounts: const [
      (2000000, 2900000, 0, 0),
      (2100000, 3100000, 0, 0),
      (1900000, 3400000, 0, 0),
      (2200000, 2800000, 0, 0),
      (2000000, 3200000, 0, 0),
      (1800000, 3600000, 100000, 0),
    ],
  ),
  includeDebtMovements: true,
  bounds: fullHistoryBounds(),
);

/// Zero everywhere — HU-06 "vacío".
CashflowSeries emptyCashflowSeries() => CashflowSeries(
  points: buildCashflowPoints(
    amounts: const [
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0),
      (0, 0, 0, 0),
    ],
  ),
  includeDebtMovements: true,
  bounds: fullHistoryBounds(),
);

/// Short-history clamp (HU-06), daily buckets over the last 10 days of data.
CashflowSeries shortHistoryCashflowSeries() {
  final bounds = shortHistoryBounds();
  return CashflowSeries(
    points: [
      for (var i = 0; i < 10; i++)
        CashflowPoint(
          periodStart: bounds.effectiveRange.start.add(Duration(days: i)),
          incomeMinor: i.isEven ? 150000 : 0,
          expenseMinor: 90000,
          debtIncomeMinor: 0,
          debtExpenseMinor: 0,
        ),
    ],
    includeDebtMovements: true,
    bounds: bounds,
  );
}

List<NetWorthPoint> _netWorthPoints(
  List<(int liquid, int total)> amounts, {
  DateTime? start,
}) {
  final base = start ?? DateTime(2025, 1, 1);
  return [
    for (var i = 0; i < amounts.length; i++)
      NetWorthPoint(
        date: DateTime(base.year, base.month + i, base.day),
        liquidMinor: amounts[i].$1,
        totalMinor: amounts[i].$2,
      ),
  ];
}

NetWorthSeries netWorthSeriesWithData() => NetWorthSeries(
  points: _netWorthPoints(const [
    (8000000, 6500000),
    (8300000, 6900000),
    (8600000, 7100000),
    (9000000, 7600000),
    (9400000, 8000000),
    (9800000, 8500000),
    (10200000, 9000000),
  ]),
  includeArchivedAccounts: false,
  bounds: fullHistoryBounds(),
);

NetWorthSeries emptyNetWorthSeries() => NetWorthSeries(
  points: _netWorthPoints(const [(0, 0), (0, 0)]),
  includeArchivedAccounts: false,
  bounds: fullHistoryBounds(),
);

NetWorthSeries shortHistoryNetWorthSeries() {
  final bounds = shortHistoryBounds();
  return NetWorthSeries(
    points: _netWorthPoints(
      const [(4200000, 3900000), (4300000, 4000000), (4500000, 4150000)],
      start: bounds.effectiveRange.start,
    ),
    includeArchivedAccounts: false,
    bounds: bounds,
  );
}

CategoryBreakdown categoryBreakdownWithData() {
  const groceries = CategoryBreakdownItem(
    categoryId: 'cat-mercado',
    name: 'Mercado',
    icon: 'shopping-cart',
    color: 'mint',
    amountMinor: 1450000,
    subcategories: [
      CategoryBreakdownItem(
        categoryId: 'cat-mercado-supermercado',
        name: 'Supermercado',
        icon: 'shopping-cart',
        color: 'mint',
        amountMinor: 1050000,
      ),
      CategoryBreakdownItem(
        categoryId: 'cat-mercado-mercado-local',
        name: 'Plaza de mercado',
        icon: 'shopping-cart',
        color: 'mint',
        amountMinor: 400000,
      ),
    ],
  );
  const transport = CategoryBreakdownItem(
    categoryId: 'cat-transporte',
    name: 'Transporte',
    icon: 'bus',
    color: 'sky',
    amountMinor: 620000,
  );
  const restaurants = CategoryBreakdownItem(
    categoryId: 'cat-restaurantes',
    name: 'Restaurantes',
    icon: 'utensils-crossed',
    color: 'peach',
    amountMinor: 480000,
  );
  const uncategorized = CategoryBreakdownItem(
    categoryId: null,
    name: null,
    amountMinor: 90000,
  );
  return CategoryBreakdown(
    items: const [groceries, transport, restaurants, uncategorized],
    totalMinor: 1450000 + 620000 + 480000 + 90000,
    range: sixMonthRangeMonthly,
  );
}

CategoryBreakdown emptyCategoryBreakdown() => CategoryBreakdown(
  items: const [],
  totalMinor: 0,
  range: sixMonthRangeMonthly,
);

BudgetWithProgress dashboardBudget() => BudgetWithProgress(
  budget: buildBudget(
    id: 'budget-mercado',
    name: 'Mercado',
    amountMinor: 1500000,
    icon: 'shopping-cart',
    startDate: DateTime(2025, 6, 1),
  ),
  scope: const BudgetScope(),
  window: BudgetPeriodWindow(
    start: DateTime(2025, 6, 1),
    endExclusive: DateTime(2025, 7, 1),
    index: 5,
    status: BudgetWindowStatus.current,
    hasPrevious: true,
    hasNext: false,
  ),
  progress: const BudgetProgress(
    amountMinor: 1500000,
    spentMinor: 1035000,
    daysLeft: 12,
  ),
);

GoalWithProgress dashboardGoal() => buildGoalWithProgress(
  goal: buildGoal(id: 'goal-viaje', name: 'Viaje a Cartagena', targetMinor: 3000000),
  savedMinor: 1800000,
  displayedPercent: 60,
);

ReportsDashboard dashboardWithData() =>
    ReportsDashboard(budgets: [dashboardBudget()], goals: [dashboardGoal()]);

ReportsDashboard emptyDashboard() =>
    const ReportsDashboard(budgets: [], goals: []);
