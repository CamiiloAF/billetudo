import 'package:equatable/equatable.dart';

import 'debt_cash_event.dart';

/// Input for registering a **cash** debt event (HU-02, toggle "Sí"): a
/// `Transaction` that carries the debt id and moves an account. The user
/// supplies a positive [amountMinor] and whether it is a disbursement or an
/// abono ([kind]); `RegisterDebtCashEvent` resolves the concrete
/// income/expense `type` and the currency from the debt itself.
class DebtCashEventDraft extends Equatable {
  const DebtCashEventDraft({
    required this.debtId,
    required this.accountId,
    required this.amountMinor,
    required this.kind,
    required this.date,
    this.note,
    this.categoryId,
  });

  final String debtId;
  final String accountId;

  /// Positive magnitude in cents.
  final int amountMinor;

  final DebtCashEventKind kind;
  final DateTime date;
  final String? note;

  /// Optional: lets the cuota hit a budget envelope (HU-02/HU-03). Never used
  /// for the balance derivation.
  final String? categoryId;

  @override
  List<Object?> get props =>
      [debtId, accountId, amountMinor, kind, date, note, categoryId];
}
