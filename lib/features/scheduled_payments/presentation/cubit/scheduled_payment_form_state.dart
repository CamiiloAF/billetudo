import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../domain/entities/scheduled_payment.dart';

enum ScheduledPaymentFormStatus {
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure
}

/// State of the create/edit template form (HU-01/HU-05).
///
/// The amount lives here as **text**, exactly as typed (same pattern as
/// `AccountFormState.initialBalanceText`): it only becomes an integer of
/// cents when the form is submitted, through `MoneyFormatter`.
class ScheduledPaymentFormState extends Equatable {
  ScheduledPaymentFormState({
    this.status = ScheduledPaymentFormStatus.loading,
    this.id,
    this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryKind,
    this.categoryName,
    this.amountText = '',
    this.currency = defaultCurrency,
    this.type = ScheduledPaymentType.expense,
    this.note = '',
    this.transferAccountId,
    this.transferAccountName,
    this.frequency = ScheduledPaymentFrequency.monthly,
    this.interval = 1,
    DateTime? nextDate,
    this.endDate,
    this.requiresConfirmation = false,
    this.tagIds = const <String>{},
    this.failure,
  }) : nextDate = nextDate ?? DateTime.now();

  static const String defaultCurrency = 'COP';

  final ScheduledPaymentFormStatus status;

  /// `null` when creating; the template id when editing.
  final String? id;

  final String? accountId;
  final String? accountName;

  final String? categoryId;
  final CategoryKind? categoryKind;
  final String? categoryName;

  final String amountText;
  final String currency;
  final ScheduledPaymentType type;
  final String note;

  final String? transferAccountId;
  final String? transferAccountName;

  final ScheduledPaymentFrequency frequency;
  final int interval;
  final DateTime nextDate;
  final DateTime? endDate;

  final bool requiresConfirmation;
  final Set<String> tagIds;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isTransfer => type == ScheduledPaymentType.transfer;
  bool get isOnce => frequency == ScheduledPaymentFrequency.once;
  bool get isSaving => status == ScheduledPaymentFormStatus.saving;

  /// The interval/endDate disclosure only makes sense for a repeating
  /// template.
  bool get showRecurrenceOptions => !isOnce;

  String? get failedField => failure is ValidationFailure
      ? (failure! as ValidationFailure).field
      : null;

  ScheduledPaymentFormState copyWith({
    ScheduledPaymentFormStatus? status,
    String? id,
    String? accountId,
    String? accountName,
    String? categoryId,
    CategoryKind? categoryKind,
    String? categoryName,
    bool clearCategory = false,
    String? amountText,
    String? currency,
    ScheduledPaymentType? type,
    String? note,
    String? transferAccountId,
    String? transferAccountName,
    bool clearTransferAccount = false,
    ScheduledPaymentFrequency? frequency,
    int? interval,
    DateTime? nextDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? requiresConfirmation,
    Set<String>? tagIds,
    Failure? failure,
  }) =>
      ScheduledPaymentFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        categoryKind:
            clearCategory ? null : (categoryKind ?? this.categoryKind),
        categoryName:
            clearCategory ? null : (categoryName ?? this.categoryName),
        amountText: amountText ?? this.amountText,
        currency: currency ?? this.currency,
        type: type ?? this.type,
        note: note ?? this.note,
        transferAccountId: clearTransferAccount
            ? null
            : (transferAccountId ?? this.transferAccountId),
        transferAccountName: clearTransferAccount
            ? null
            : (transferAccountName ?? this.transferAccountName),
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        nextDate: nextDate ?? this.nextDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
        tagIds: type == ScheduledPaymentType.transfer
            ? const <String>{}
            : (tagIds ?? this.tagIds),
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        id,
        accountId,
        accountName,
        categoryId,
        categoryKind,
        categoryName,
        amountText,
        currency,
        type,
        note,
        transferAccountId,
        transferAccountName,
        frequency,
        interval,
        nextDate,
        endDate,
        requiresConfirmation,
        tagIds,
        failure,
      ];
}
