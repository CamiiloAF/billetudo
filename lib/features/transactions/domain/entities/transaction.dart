import 'package:equatable/equatable.dart';

/// The nature of a transaction. Mirrors `EntryType` stored as text in Drift,
/// but is declared here so the domain never depends on the database layer.
enum TransactionType { income, expense, transfer }

/// How a transaction was captured. Mirrors `TxSource`. Used to measure AI
/// usage and calibrate quotas: `manual` and `imported` cost nothing; the rest
/// are reserved for later phases (voice/OCR/notification capture,
/// transactions auto-generated from a scheduled payment).
enum TransactionSource { manual, voice, ocr, notification, imported, scheduled }

/// A single transaction: income, expense or transfer between accounts.
///
/// Pure domain entity: no Drift types, no `double`. `amountMinor` is always a
/// positive integer of minor units (cents); the sign/effect on the balance is
/// determined by [type], never by a negative amount (see `03-transacciones.md`).
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.note,
    this.transferAccountId,
    this.scheduledPaymentId,
    this.goalId,
    this.debtId,
  });

  /// UUID as text.
  final String id;

  final String accountId;

  /// Optional, restricted to a category whose `kind` matches [type]
  /// (`income`/`expense`). Never set for a `transfer` (HU-01/02/03).
  final String? categoryId;

  /// Always a positive integer of cents. The sign is determined by [type].
  final int amountMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'.
  final String currency;

  final TransactionType type;
  final DateTime date;
  final String? note;

  /// Capture origin. Immutable once created (HU-04): editing a transaction
  /// never rewrites how it was captured.
  final TransactionSource source;

  /// Only set when [type] is `transfer`: the destination account.
  final String? transferAccountId;

  /// Optional links to other features.
  final String? scheduledPaymentId;
  final String? goalId;
  final String? debtId;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` (schema v5) — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  bool get isTransfer => type == TransactionType.transfer;

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        amountMinor,
        currency,
        type,
        date,
        note,
        source,
        transferAccountId,
        scheduledPaymentId,
        goalId,
        debtId,
        createdAt,
        updatedAt,
      ];
}
