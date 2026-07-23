import 'package:equatable/equatable.dart';

/// A single row of the unified debt history (HU-04): cash `Transaction`s and
/// solo-deuda `DebtEntry`s merged and sorted, each with its signed effect on
/// the balance already resolved by `DebtBalanceCalculator`.
enum DebtLedgerKind {
  /// The opening balance (`principalMinor`), synthesized as the first row.
  opening,

  /// A cash disbursement — a `Transaction` that increased the debt.
  cashDisbursement,

  /// A cash abono/cuota — a `Transaction` that reduced the debt.
  cashPayment,

  /// A cash-less disbursement `DebtEntry` (toggle "No").
  ledgerDisbursement,

  /// A cash-less abono `DebtEntry` (toggle "No").
  ledgerPayment,

  /// An interest accrual `DebtEntry`.
  interestAccrual,

  /// A manual reconciliation `DebtEntry`.
  manualAdjustment,
}

/// One unified history item. Pure domain: the presentation layer renders it
/// without re-deriving any sign.
class DebtLedgerEntry extends Equatable {
  const DebtLedgerEntry({
    required this.id,
    required this.kind,
    required this.date,
    required this.effectMinor,
    this.note,
    this.transactionId,
    this.entryId,
  });

  /// Stable id for lists — the underlying transaction/entry id, or `opening`.
  final String id;

  final DebtLedgerKind kind;
  final DateTime date;

  /// Signed effect on the debt: + increased it, − reduced it.
  final int effectMinor;

  final String? note;

  /// Set for cash rows; the `Transaction` behind this item.
  final String? transactionId;

  /// Set for solo-deuda rows; the `DebtEntry` behind this item.
  final String? entryId;

  bool get isCashEvent => transactionId != null;

  @override
  List<Object?> get props => [
        id,
        kind,
        date,
        effectMinor,
        note,
        transactionId,
        entryId,
      ];
}
