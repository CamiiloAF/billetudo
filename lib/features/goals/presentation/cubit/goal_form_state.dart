import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';

/// The lifecycle of crear/editar meta (HU-01/HU-02/HU-08).
enum GoalFormStatus { loading, ready, saving, saved, deleted, failure }

/// Crear/editar meta form state.
///
/// Money is cents ([targetMinor]/[initialSavedMinor]) — never a `double`. All
/// validation lives in `GoalDraft.validated()`; the cubit only surfaces the
/// [failedField] the use case reported.
class GoalFormState extends Equatable {
  const GoalFormState({
    this.status = GoalFormStatus.loading,
    this.id,
    this.name = '',
    this.targetMinor = 0,
    this.currency = 'COP',
    this.targetDate,
    this.icon,
    this.accountId,
    this.initialSavedMinor = 0,
    this.accounts = const [],
    this.failedField,
    this.failure,
  });

  final GoalFormStatus status;

  /// `null` when creating; the goal id when editing.
  final String? id;

  final String name;
  final int targetMinor;
  final String currency;
  final DateTime? targetDate;
  final String? icon;

  /// HU-02: the linked account, when set. The currency field is locked to
  /// this account's currency while it is non-null.
  final String? accountId;

  /// HU-01: an already-existing amount declared only on create. Ignored once
  /// editing (the form never shows it again — the real progress lives in the
  /// ledger from then on).
  final int initialSavedMinor;

  /// Active accounts, for the account picker.
  final List<AccountWithBalance> accounts;

  /// The `GoalDraft` field the last submit failed on, for the inline error.
  final String? failedField;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isSaving => status == GoalFormStatus.saving;

  /// HU-02: whether the currency field is locked (an account is linked).
  bool get isCurrencyLocked => accountId != null;

  GoalFormState copyWith({
    GoalFormStatus? status,
    String? id,
    String? name,
    int? targetMinor,
    String? currency,
    DateTime? Function()? targetDate,
    String? Function()? icon,
    String? Function()? accountId,
    int? initialSavedMinor,
    List<AccountWithBalance>? accounts,
    String? Function()? failedField,
    Failure? Function()? failure,
  }) =>
      GoalFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        name: name ?? this.name,
        targetMinor: targetMinor ?? this.targetMinor,
        currency: currency ?? this.currency,
        targetDate: targetDate == null ? this.targetDate : targetDate(),
        icon: icon == null ? this.icon : icon(),
        accountId: accountId == null ? this.accountId : accountId(),
        initialSavedMinor: initialSavedMinor ?? this.initialSavedMinor,
        accounts: accounts ?? this.accounts,
        failedField: failedField == null ? this.failedField : failedField(),
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        status,
        id,
        name,
        targetMinor,
        currency,
        targetDate,
        icon,
        accountId,
        initialSavedMinor,
        accounts,
        failedField,
        failure,
      ];
}
