import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/budget_period_override.dart';

/// Translates a `BudgetPeriodOverrides` Drift row into its domain entity. Kept
/// in `data/` so the generated `BudgetPeriodOverrideRow` type never escapes the
/// layer. `periodStart` is normalized to date-only, the same shape
/// `BudgetPeriodWindow.start` uses, so the two compare and index by equality.
abstract final class BudgetPeriodOverrideMapper {
  static BudgetPeriodOverride toEntity(db.BudgetPeriodOverrideRow row) =>
      BudgetPeriodOverride(
        id: row.id,
        budgetId: row.budgetId,
        periodStart: dateOnly(row.periodStart),
        amountMinor: row.amountMinor,
      );

  /// Strips the time part so a stored `periodStart` compares equal to a
  /// calculator-produced `BudgetPeriodWindow.start` (both local, midnight).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
