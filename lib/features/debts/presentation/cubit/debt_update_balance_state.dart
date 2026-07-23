import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';

/// The lifecycle of the actualizar-saldo sheet.
enum DebtUpdateBalanceStatus { ready, saving, saved, failure }

/// The actualizar-saldo (reconciliation) sheet state (`DEWMf`, HU-06).
///
/// The user types the real figure ([targetMinor]); the app records a
/// `manualAdjustment` `DebtEntry` that absorbs the difference against the
/// current derived balance ([currentOutstandingMinor], the "saldo estimado
/// hoy"). Never touches an account.
class DebtUpdateBalanceState extends Equatable {
  const DebtUpdateBalanceState({
    required this.debt,
    required this.currentOutstandingMinor,
    required this.targetMinor,
    required this.date,
    this.status = DebtUpdateBalanceStatus.ready,
    this.note = '',
    this.failure,
  });

  final Debt debt;

  /// The raw derived outstanding used both for the "saldo estimado hoy" line
  /// and for the adjustment diff, so the two always agree.
  final int currentOutstandingMinor;

  /// The figure the user is reconciling to.
  final int targetMinor;

  final DateTime date;
  final DebtUpdateBalanceStatus status;
  final String note;
  final Failure? failure;

  bool get isSaving => status == DebtUpdateBalanceStatus.saving;

  /// Signed adjustment that will be recorded: + when the debt grows to meet the
  /// figure, − when it shrinks. Shown in a neutral tone, never `$expense`.
  int get adjustmentMinor => targetMinor - currentOutstandingMinor;

  bool get canSubmit => targetMinor >= 0 && !isSaving;

  DebtUpdateBalanceState copyWith({
    int? targetMinor,
    DateTime? date,
    DebtUpdateBalanceStatus? status,
    String? note,
    Failure? Function()? failure,
  }) =>
      DebtUpdateBalanceState(
        debt: debt,
        currentOutstandingMinor: currentOutstandingMinor,
        targetMinor: targetMinor ?? this.targetMinor,
        date: date ?? this.date,
        status: status ?? this.status,
        note: note ?? this.note,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        debt,
        currentOutstandingMinor,
        targetMinor,
        date,
        status,
        note,
        failure,
      ];
}
