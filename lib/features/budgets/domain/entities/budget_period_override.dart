import 'package:equatable/equatable.dart';

/// A per-period amount override for a recurring budget (Wallet-style): for the
/// single window that starts on [periodStart], the budget's target amount is
/// [amountMinor] instead of `Budget.amountMinor`. Every other period keeps the
/// original amount.
///
/// This is the storage behind "Ajustar monto — solo el próximo período": one
/// row per (budgetId, periodStart), replacing the old multi-row "fork" model.
/// Pure domain entity: no Drift types, cents as integers.
class BudgetPeriodOverride extends Equatable {
  const BudgetPeriodOverride({
    required this.id,
    required this.budgetId,
    required this.periodStart,
    required this.amountMinor,
  });

  /// UUID as text.
  final String id;
  final String budgetId;

  /// Date-only start of the overridden window (`BudgetPeriodWindow.start`).
  final DateTime periodStart;

  /// The overriding target amount, always a positive integer of cents.
  final int amountMinor;

  @override
  List<Object?> get props => [id, budgetId, periodStart, amountMinor];
}
