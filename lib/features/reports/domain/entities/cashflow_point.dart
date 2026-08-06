import 'package:equatable/equatable.dart';

/// Income/expense/net for a single bucket (a month or a day, per
/// `DateRange.granularity`) of the flujo de caja report (HU-01).
///
/// Carries both the non-debt and debt-linked amounts always, regardless of
/// the "movimientos de deuda" toggle: the toggle only changes how the
/// presentation layer groups them into series (merged vs. segregated), never
/// what was fetched — so switching it never re-queries. [netMinor] is always
/// the full total (everything in, everything out); criterion "sin alterar el
/// total normal" (HU-01) depends on that being toggle-independent.
class CashflowPoint extends Equatable {
  const CashflowPoint({
    required this.periodStart,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.debtIncomeMinor,
    required this.debtExpenseMinor,
  });

  /// Start of the bucket (first day of the month, or the day itself for
  /// daily granularity).
  final DateTime periodStart;

  /// Non-debt income for the bucket: `type == income && debtId == null`.
  final int incomeMinor;

  /// Non-debt expense for the bucket: `type == expense && debtId == null`,
  /// plus `type == transfer && countsInBudget` (origin side only, per
  /// "Reglas de conteo").
  final int expenseMinor;

  /// Debt-linked income for the bucket (`debtId != null`).
  final int debtIncomeMinor;

  /// Debt-linked expense for the bucket (`debtId != null`).
  final int debtExpenseMinor;

  /// Everything in minus everything out, debt included — never affected by
  /// how the caller chooses to group the two series.
  int get netMinor =>
      (incomeMinor + debtIncomeMinor) - (expenseMinor + debtExpenseMinor);

  @override
  List<Object?> get props => [
        periodStart,
        incomeMinor,
        expenseMinor,
        debtIncomeMinor,
        debtExpenseMinor,
      ];
}
