import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart' show TransactionType;

/// A **cash event** against a debt: a `Transaction` that carries the debt's id
/// and therefore moved one of the user's accounts (took the loan / paid a
/// cuota). The projection the debt derivation needs, without hauling the whole
/// `Transaction` entity around — keeps `DebtBalanceCalculator` trivial to test.
///
/// Whether it increases or reduces the debt is NOT stored here: it is derived
/// from the debt's `direction` × [type] (see `DebtEventRules.cashEventEffect`),
/// because the same `income`/`expense` means opposite things depending on which
/// way the debt points.
class DebtCashEvent extends Equatable {
  const DebtCashEvent({
    required this.transactionId,
    required this.type,
    required this.amountMinor,
    required this.date,
    required this.createdAt,
    this.note,
  });

  /// The id of the underlying `Transaction`.
  final String transactionId;

  /// The transaction's money direction. Never `transfer` for a debt event.
  final TransactionType type;

  /// The transaction's amount in cents, always positive (the sign/effect on the
  /// debt is derived from `direction` × [type]).
  final int amountMinor;

  final DateTime date;

  /// When the underlying `Transaction` row was created. Used only as a
  /// same-day tiebreak when ordering the unified ledger (newest-created first),
  /// so the opening row sinks to the bottom of its day. Not shown in the UI.
  final DateTime createdAt;

  final String? note;

  @override
  List<Object?> get props => [
        transactionId,
        type,
        amountMinor,
        date,
        createdAt,
        note,
      ];
}

/// Which kind of cash event the user is registering from a debt sheet, before
/// it is resolved into an `income`/`expense` `Transaction`.
///  - `disbursement`: the loan is taken/given (increases the debt).
///  - `payment`: an abono/cuota (reduces the debt).
enum DebtCashEventKind { disbursement, payment }
