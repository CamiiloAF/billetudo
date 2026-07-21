import 'package:billetudo/features/budgets/domain/entities/budget.dart';

/// Minimal [Budget] builder for the domain tests.
Budget buildBudget({
  String id = 'b1',
  String name = 'Test',
  int amountMinor = 600000,
  String currency = 'COP',
  BudgetPeriod period = BudgetPeriod.monthly,
  required DateTime startDate,
  bool recurring = true,
  DateTime? endDate,
  int? alertThresholdPct = 80,
  bool rollover = false,
  String? icon,
  DateTime? archivedAt,
  DateTime? createdAt,
}) =>
    Budget(
      id: id,
      name: name,
      icon: icon,
      archivedAt: archivedAt,
      amountMinor: amountMinor,
      currency: currency,
      period: period,
      startDate: startDate,
      recurring: recurring,
      endDate: endDate,
      alertThresholdPct: alertThresholdPct,
      rollover: rollover,
      createdAt: createdAt ?? DateTime(2024),
      updatedAt: 0,
    );
