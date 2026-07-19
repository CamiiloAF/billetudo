import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/tag.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';

/// Shared builders so each test only states what it is actually about.
final DateTime testInstant = DateTime(2026, 7, 15, 10, 30);

/// `updatedAt` is epoch millis (schema v5), unlike `createdAt`.
final int testInstantMillis = testInstant.millisecondsSinceEpoch;

Transaction buildTransaction({
  String id = 'tx-1',
  String accountId = 'acc-1',
  String? categoryId,
  int amountMinor = 10000,
  String currency = 'COP',
  TransactionType type = TransactionType.expense,
  DateTime? date,
  String? note,
  TransactionSource source = TransactionSource.manual,
  String? transferAccountId,
  String? scheduledPaymentId,
  String? goalId,
  String? debtId,
  int? updatedAt,
}) =>
    Transaction(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currency: currency,
      type: type,
      date: date ?? testInstant,
      note: note,
      source: source,
      transferAccountId: transferAccountId,
      scheduledPaymentId: scheduledPaymentId,
      goalId: goalId,
      debtId: debtId,
      createdAt: testInstant,
      updatedAt: updatedAt ?? testInstantMillis,
    );

/// A valid expense draft: tests override only the field under test.
///
/// [categoryId]/[categoryKind] default to a matching expense category since
/// `TransactionDraft.validated` now requires one — pass `categoryId: null`
/// explicitly to exercise that rejection.
TransactionDraft buildExpenseDraft({
  String? id,
  String accountId = 'acc-1',
  String? categoryId = 'cat-expense-1',
  CategoryKind? categoryKind = CategoryKind.expense,
  int amountMinor = 10000,
  String currency = 'COP',
  DateTime? date,
  String? note,
  TransactionSource source = TransactionSource.manual,
  String? scheduledPaymentId,
  String? goalId,
  String? debtId,
}) =>
    TransactionDraft(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      categoryKind: categoryKind,
      amountMinor: amountMinor,
      currency: currency,
      type: TransactionType.expense,
      date: date ?? testInstant,
      note: note,
      source: source,
      scheduledPaymentId: scheduledPaymentId,
      goalId: goalId,
      debtId: debtId,
    );

/// [categoryId]/[categoryKind] default to a matching income category since
/// `TransactionDraft.validated` now requires one — pass `categoryId: null`
/// explicitly to exercise that rejection.
TransactionDraft buildIncomeDraft({
  String? id,
  String accountId = 'acc-1',
  String? categoryId = 'cat-income-1',
  CategoryKind? categoryKind = CategoryKind.income,
  int amountMinor = 10000,
  String currency = 'COP',
  DateTime? date,
  String? note,
}) =>
    TransactionDraft(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      categoryKind: categoryKind,
      amountMinor: amountMinor,
      currency: currency,
      type: TransactionType.income,
      date: date ?? testInstant,
      note: note,
    );

TransactionDraft buildTransferDraft({
  String? id,
  String accountId = 'acc-1',
  String? transferAccountId = 'acc-2',
  int amountMinor = 10000,
  String currency = 'COP',
  DateTime? date,
  String? note,
}) =>
    TransactionDraft(
      id: id,
      accountId: accountId,
      transferAccountId: transferAccountId,
      amountMinor: amountMinor,
      currency: currency,
      type: TransactionType.transfer,
      date: date ?? testInstant,
      note: note,
    );

Tag buildTag({
  String id = 'tag-1',
  String name = 'viaje',
  String? color,
  int? updatedAt,
}) =>
    Tag(
      id: id,
      name: name,
      color: color,
      createdAt: testInstant,
      updatedAt: updatedAt ?? testInstantMillis,
    );
