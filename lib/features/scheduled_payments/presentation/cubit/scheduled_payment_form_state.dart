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
    this.originalNextDate,
    this.nextDateEdited = false,
    this.endDate,
    this.requiresConfirmation = false,
    this.tagIds = const <String>{},
    this.debtId,
    this.debtName,
    this.debtIsIOwe = false,
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

  /// The value the "Primer pago"/"Fecha del pago" field shows and edits.
  /// Populated from `ScheduledPayment.firstPaymentDate` on `load()` — never
  /// from the live `nextDate` cursor, which the catch-up generator advances
  /// on its own (that drift is exactly the bug this field must not show).
  final DateTime nextDate;

  /// The template's actual `nextDate` cursor as loaded, kept aside (never
  /// shown) so an edit-and-save that never touches the date field submits
  /// this unchanged value instead of silently resetting the cursor back to
  /// `firstPaymentDate`. Null while creating (there is no live cursor yet).
  final DateTime? originalNextDate;

  /// Whether the user has explicitly changed the date field during this
  /// editing session (via `ScheduledPaymentFormCubit.nextDateChanged`).
  /// HU-05 lets the user move the schedule's date on purpose; this flag is
  /// what tells `_buildDraft` an edit is intentional rather than the
  /// untouched display value.
  final bool nextDateEdited;

  final DateTime? endDate;

  final bool requiresConfirmation;
  final Set<String> tagIds;

  /// The owning debt id when the form is in "cuota de deuda" mode (HU-03),
  /// null for an ordinary scheduled payment. Persisted on the draft so the
  /// cuota keeps its link across edits (see `ScheduledPaymentFormCubit.load`).
  final String? debtId;

  /// The owning debt's display name and direction, only for rendering the
  /// cuota header subtitle ("Crédito vehicular · Yo debo") — never persisted.
  final String? debtName;
  final bool debtIsIOwe;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isTransfer => type == ScheduledPaymentType.transfer;
  bool get isOnce => frequency == ScheduledPaymentFrequency.once;
  bool get isSaving => status == ScheduledPaymentFormStatus.saving;

  /// Whether the form is configuring a debt's cuota (HU-03): the type segmented
  /// control is hidden (the type is derived from the debt's direction), a
  /// cross-link banner and a context subtitle are shown, and the saved template
  /// carries [debtId].
  bool get isDebtInstallment => debtId != null;

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
    bool nextDateEdited = false,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? requiresConfirmation,
    Set<String>? tagIds,
    String? debtId,
    String? debtName,
    bool? debtIsIOwe,
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
        // No `originalNextDate` parameter on purpose: it is only ever set
        // once, by `load()`'s direct constructor call, and must survive
        // every subsequent `copyWith` untouched — the bare reference below
        // resolves to `this.originalNextDate`.
        originalNextDate: originalNextDate,
        nextDateEdited: nextDateEdited || this.nextDateEdited,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
        tagIds: type == ScheduledPaymentType.transfer
            ? const <String>{}
            : (tagIds ?? this.tagIds),
        debtId: debtId ?? this.debtId,
        debtName: debtName ?? this.debtName,
        debtIsIOwe: debtIsIOwe ?? this.debtIsIOwe,
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
        originalNextDate,
        nextDateEdited,
        endDate,
        requiresConfirmation,
        tagIds,
        debtId,
        debtName,
        debtIsIOwe,
        failure,
      ];
}
