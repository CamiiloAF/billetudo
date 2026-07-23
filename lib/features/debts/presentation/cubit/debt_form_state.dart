import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';

/// The lifecycle of the crear/editar deuda form (`dUryC`).
enum DebtFormStatus { loading, ready, saving, saved, deleted, failure }

/// The crear/editar deuda form state (HU-01/HU-05).
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
    this.amountMinor = 0,
    this.name = '',
    this.counterparty = '',
    this.currency = 'COP',
    this.dueDate,
    this.rateText = '',
    this.accrualMode = DebtAccrualMode.manual,
    this.failedField,
    this.failure,
  });

  final DebtFormStatus status;

  /// null when creating; the debt id when editing.
  final String? id;

  final DebtDirection direction;
  final int amountMinor;
  final String name;
  final String counterparty;
  final String currency;
  final DateTime? dueDate;
  final String rateText;
  final DebtAccrualMode accrualMode;

  /// The `DebtDraft` field the last submit failed on, for the inline error.
  final String? failedField;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isSaving => status == DebtFormStatus.saving;

  DebtFormState copyWith({
    DebtFormStatus? status,
    String? id,
    DebtDirection? direction,
    int? amountMinor,
    String? name,
    String? counterparty,
    String? currency,
    DateTime? Function()? dueDate,
    String? rateText,
    DebtAccrualMode? accrualMode,
    String? Function()? failedField,
    Failure? Function()? failure,
  }) =>
      DebtFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        direction: direction ?? this.direction,
        amountMinor: amountMinor ?? this.amountMinor,
        name: name ?? this.name,
        counterparty: counterparty ?? this.counterparty,
        currency: currency ?? this.currency,
        dueDate: dueDate == null ? this.dueDate : dueDate(),
        rateText: rateText ?? this.rateText,
        accrualMode: accrualMode ?? this.accrualMode,
        failedField: failedField == null ? this.failedField : failedField(),
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        status,
        id,
        direction,
        amountMinor,
        name,
        counterparty,
        currency,
        dueDate,
        rateText,
        accrualMode,
        failedField,
        failure,
      ];
}
