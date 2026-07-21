import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';

/// Shared builders so each test only states what it is actually about.
final DateTime testInstant = DateTime(2026, 7, 15, 10, 30);

/// `updatedAt` is epoch millis, unlike `createdAt`.
final int testInstantMillis = testInstant.millisecondsSinceEpoch;

ScheduledPayment buildScheduledPayment({
  String id = 'sp-1',
  String accountId = 'acc-1',
  String? categoryId,
  int amountMinor = 10000,
  String currency = 'COP',
  ScheduledPaymentType type = ScheduledPaymentType.expense,
  String? note,
  String? transferAccountId,
  ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.monthly,
  int interval = 1,
  DateTime? firstPaymentDate,
  DateTime? nextDate,
  DateTime? endDate,
  bool requiresConfirmation = false,
  DateTime? tombstonedAt,
  int? updatedAt,
}) =>
    ScheduledPayment(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currency: currency,
      type: type,
      note: note,
      transferAccountId: transferAccountId,
      frequency: frequency,
      interval: interval,
      // Defaults to the same value as `nextDate` (or `testInstant`) so
      // existing fixtures that never touched the recurrence cursor stay
      // coherent: the immutable "first payment" and the live cursor start
      // out equal, and only diverge once the generator advances `nextDate`.
      firstPaymentDate: firstPaymentDate ?? nextDate ?? testInstant,
      nextDate: nextDate ?? testInstant,
      endDate: endDate,
      requiresConfirmation: requiresConfirmation,
      createdAt: testInstant,
      updatedAt: updatedAt ?? testInstantMillis,
      tombstonedAt: tombstonedAt,
    );

/// [categoryId]/[categoryKind] default to a matching expense category since
/// `ScheduledPaymentDraft.validated` now requires one for a gasto/ingreso
/// template — pass `categoryId: null` to exercise the "sin categoría" path.
ScheduledPaymentDraft buildExpenseDraft({
  String? id,
  String accountId = 'acc-1',
  String? categoryId = 'cat-expense-1',
  CategoryKind? categoryKind = CategoryKind.expense,
  int amountMinor = 10000,
  String currency = 'COP',
  DateTime? nextDate,
  DateTime? endDate,
  String? note,
  ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.monthly,
  int interval = 1,
  bool requiresConfirmation = false,
  List<String> tagIds = const <String>[],
}) =>
    ScheduledPaymentDraft(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      categoryKind: categoryKind,
      amountMinor: amountMinor,
      currency: currency,
      type: ScheduledPaymentType.expense,
      frequency: frequency,
      interval: interval,
      nextDate: nextDate ?? testInstant,
      endDate: endDate,
      note: note,
      requiresConfirmation: requiresConfirmation,
      tagIds: tagIds,
    );

ScheduledPaymentOccurrence buildOccurrence({
  String id = 'occ-1',
  String scheduledPaymentId = 'sp-1',
  DateTime? occurrenceDate,
  ScheduledOccurrenceStatus status = ScheduledOccurrenceStatus.pending,
  DateTime? snoozedToDate,
  String? generatedTransactionId,
}) =>
    ScheduledPaymentOccurrence(
      id: id,
      scheduledPaymentId: scheduledPaymentId,
      occurrenceDate: occurrenceDate ?? testInstant,
      status: status,
      snoozedToDate: snoozedToDate,
      generatedTransactionId: generatedTransactionId,
      createdAt: testInstant,
      updatedAt: testInstantMillis,
    );

PendingScheduledOccurrence buildPendingOccurrence({
  ScheduledPaymentOccurrence? occurrence,
  ScheduledPayment? scheduledPayment,
  String accountName = 'Bancolombia',
  String? categoryName,
  String? categoryIcon,
  String? categoryColor,
  String? transferAccountName,
  List<String> tagIds = const <String>[],
}) =>
    PendingScheduledOccurrence(
      occurrence: occurrence ?? buildOccurrence(),
      scheduledPayment:
          scheduledPayment ?? buildScheduledPayment(requiresConfirmation: true),
      accountName: accountName,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      transferAccountName: transferAccountName,
      tagIds: tagIds,
    );

ScheduledPaymentDraft buildTransferDraft({
  String? id,
  String accountId = 'acc-1',
  String? transferAccountId = 'acc-2',
  int amountMinor = 10000,
  String currency = 'COP',
  DateTime? nextDate,
  ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.once,
  List<String> tagIds = const <String>[],
}) =>
    ScheduledPaymentDraft(
      id: id,
      accountId: accountId,
      transferAccountId: transferAccountId,
      amountMinor: amountMinor,
      currency: currency,
      type: ScheduledPaymentType.transfer,
      frequency: frequency,
      nextDate: nextDate ?? testInstant,
      tagIds: tagIds,
    );
