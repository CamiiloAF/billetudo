import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';

/// Shared builders so each test only spells out the field under test.
Debt buildDebt({
  String id = 'd1',
  String name = 'Crédito carro',
  DebtDirection direction = DebtDirection.iOwe,
  int principalMinor = 0,
  String currency = 'COP',
  DebtAccrualMode accrualMode = DebtAccrualMode.manual,
  int? interestRateBps,
  String? counterparty,
  DateTime? dueDate,
  DateTime? startDate,
  DateTime? createdAt,
  DateTime? deletedAt,
  String? initialTransactionId,
}) =>
    Debt(
      id: id,
      name: name,
      direction: direction,
      principalMinor: principalMinor,
      currency: currency,
      accrualMode: accrualMode,
      interestRateBps: interestRateBps,
      counterparty: counterparty,
      dueDate: dueDate,
      startDate: startDate,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: (createdAt ?? DateTime(2026, 1, 1)).millisecondsSinceEpoch,
      deletedAt: deletedAt,
      initialTransactionId: initialTransactionId,
    );

DebtEntry buildEntry({
  String id = 'e1',
  String debtId = 'd1',
  DebtEntryKind kind = DebtEntryKind.manualAdjustment,
  int amountMinor = 0,
  DateTime? entryDate,
  DateTime? createdAt,
  int? rateBpsSnapshot,
}) =>
    DebtEntry(
      id: id,
      debtId: debtId,
      kind: kind,
      amountMinor: amountMinor,
      entryDate: entryDate ?? DateTime(2026, 2, 1),
      rateBpsSnapshot: rateBpsSnapshot,
      createdAt: createdAt ?? DateTime(2026, 2, 1),
      updatedAt: (createdAt ?? DateTime(2026, 2, 1)).millisecondsSinceEpoch,
    );

DebtCashEvent buildCashEvent({
  String transactionId = 't1',
  TransactionType type = TransactionType.expense,
  int amountMinor = 0,
  DateTime? date,
  DateTime? createdAt,
}) =>
    DebtCashEvent(
      transactionId: transactionId,
      type: type,
      amountMinor: amountMinor,
      date: date ?? DateTime(2026, 3, 1),
      createdAt: createdAt ?? DateTime(2026, 3, 1),
    );
