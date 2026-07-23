import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/debt.dart';

/// The lifecycle of the crear/editar deuda form (`dUryC`).
enum DebtFormStatus { loading, ready, saving, saved, deleted, failure }

/// A one-shot sheet the page must open in response to the CTA (item 2 / 2b).
/// Transient: the page clears it (via the cubit) as soon as it is handled, so
/// it never re-triggers on an unrelated rebuild.
sealed class DebtFormPrompt extends Equatable {
  const DebtFormPrompt();
}

/// Item 2: ask whether to create a registro inicial (sheet `EXQfv`).
class DebtChooseRegistroPrompt extends DebtFormPrompt {
  const DebtChooseRegistroPrompt();

  @override
  List<Object?> get props => const [];
}

/// Item 2b: confirm updating the linked opening movement (sheet `hLe9z`),
/// carrying the amounts for the "de $X a $Y" copy.
class DebtConfirmUpdateRegistroPrompt extends DebtFormPrompt {
  const DebtConfirmUpdateRegistroPrompt({
    required this.fromMinor,
    required this.toMinor,
  });

  final int fromMinor;
  final int toMinor;

  @override
  List<Object?> get props => [fromMinor, toMinor];
}

/// The crear/editar deuda form state (HU-01/HU-05 + item 2/2b).
///
/// Money is cents ([amountMinor]); the interest rate is kept as the raw text
/// the user typed and parsed to whole basis points only on submit, so the
/// field round-trips exactly. All validation lives in `DebtDraft.validated()` —
/// the cubit only surfaces the [failedField] it reported.
class DebtFormState extends Equatable {
  const DebtFormState({
    this.status = DebtFormStatus.loading,
    this.id,
    this.direction = DebtDirection.iOwe,
    this.directionBaseline = DebtDirection.iOwe,
    this.amountMinor = 0,
    this.name = '',
    this.counterparty = '',
    this.currency = 'COP',
    this.startDate,
    this.startDateBaseline,
    this.dueDate,
    this.rateText = '',
    this.accrualMode = DebtAccrualMode.manual,
    this.accounts = const [],
    this.initialTransactionId,
    this.openingBaselineMinor = 0,
    this.prompt,
    this.failedField,
    this.failure,
  });

  final DebtFormStatus status;

  /// null when creating; the debt id when editing.
  final String? id;

  final DebtDirection direction;

  /// The debt's direction as it was loaded (edit only). Used to detect a
  /// direction-only change so the linked opening movement's type is re-synced
  /// silently (item 2b), without a money-decision sheet.
  final DebtDirection directionBaseline;

  final int amountMinor;
  final String name;
  final String counterparty;
  final String currency;

  /// The day the debt started (HU-01). Required, defaults to today for a new
  /// debt, never in the future. Never cleared by the user.
  final DateTime? startDate;

  /// The debt's start date as it was loaded (edit only). Used to detect a
  /// start-date change so the linked opening movement's date is re-synced
  /// silently (item 2b) — the registro inicial IS the debt's opening event, so
  /// its date always follows `startDate`. `null` when creating.
  final DateTime? startDateBaseline;

  final DateTime? dueDate;
  final String rateText;
  final DebtAccrualMode accrualMode;

  /// Active accounts, for the registro-inicial account picker (item 2). Loaded
  /// once when the form cubit loads, the same pattern `DebtPaymentCubit` uses.
  final List<AccountWithBalance> accounts;

  /// When editing a debt that already has a registro inicial, the id of its
  /// linked opening movement (item 2b). `null` for a classic debt.
  final String? initialTransactionId;

  /// The opening figure the form loaded with — the linked movement's amount
  /// when [initialTransactionId] is set, else the debt's principal. Used on
  /// edit to detect whether the opening balance changed.
  final int openingBaselineMinor;

  /// A sheet the page must open next (item 2 / 2b), or `null`.
  final DebtFormPrompt? prompt;

  /// The `DebtDraft` field the last submit failed on, for the inline error.
  final String? failedField;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isSaving => status == DebtFormStatus.saving;
  bool get hasInitialMovement => initialTransactionId != null;

  DebtFormState copyWith({
    DebtFormStatus? status,
    String? id,
    DebtDirection? direction,
    DebtDirection? directionBaseline,
    int? amountMinor,
    String? name,
    String? counterparty,
    String? currency,
    DateTime? startDate,
    DateTime? startDateBaseline,
    DateTime? Function()? dueDate,
    String? rateText,
    DebtAccrualMode? accrualMode,
    List<AccountWithBalance>? accounts,
    String? Function()? initialTransactionId,
    int? openingBaselineMinor,
    DebtFormPrompt? Function()? prompt,
    String? Function()? failedField,
    Failure? Function()? failure,
  }) =>
      DebtFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        direction: direction ?? this.direction,
        directionBaseline: directionBaseline ?? this.directionBaseline,
        amountMinor: amountMinor ?? this.amountMinor,
        name: name ?? this.name,
        counterparty: counterparty ?? this.counterparty,
        currency: currency ?? this.currency,
        startDate: startDate ?? this.startDate,
        startDateBaseline: startDateBaseline ?? this.startDateBaseline,
        dueDate: dueDate == null ? this.dueDate : dueDate(),
        rateText: rateText ?? this.rateText,
        accrualMode: accrualMode ?? this.accrualMode,
        accounts: accounts ?? this.accounts,
        initialTransactionId: initialTransactionId == null
            ? this.initialTransactionId
            : initialTransactionId(),
        openingBaselineMinor: openingBaselineMinor ?? this.openingBaselineMinor,
        prompt: prompt == null ? this.prompt : prompt(),
        failedField: failedField == null ? this.failedField : failedField(),
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        status,
        id,
        direction,
        directionBaseline,
        amountMinor,
        name,
        counterparty,
        currency,
        startDate,
        startDateBaseline,
        dueDate,
        rateText,
        accrualMode,
        accounts,
        initialTransactionId,
        openingBaselineMinor,
        prompt,
        failedField,
        failure,
      ];
}
