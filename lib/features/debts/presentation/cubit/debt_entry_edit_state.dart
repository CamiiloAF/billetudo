import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt_entry.dart';

/// The lifecycle of `DebtEntryEditSheet`. `deleting` only ever follows a
/// [DebtEntryEditState.editable] `false` state's own "Eliminar" button or an
/// editable state's "Eliminar movimiento" link — never `submit()`, which only
/// drives `ready`/`saving`. Both a successful save and a successful delete
/// land on `saved`, the single signal the sheet listens on to dismiss itself.
enum DebtEntryEditStatus { ready, saving, deleting, saved }

/// State for viewing/editing a solo-deuda [DebtEntry] (a cash-less abono,
/// desembolso, an interest accrual, or a manual adjustment).
///
/// [editable] is `false` only for an `interestAccrual` — it is
/// auto-generated, never hand-edited (`UpdateDebtEntry` is the actual
/// enforcement; this only decides what the sheet renders). An editable entry
/// exposes amount/date/note and a "Guardar cambios" CTA; a non-editable one
/// renders the same fields as plain info rows and offers only "Eliminar".
/// Both variants can delete the entry outright.
class DebtEntryEditState extends Equatable {
  const DebtEntryEditState({
    required this.entry,
    required this.amountMinor,
    required this.date,
    required this.runningMinor,
    this.status = DebtEntryEditStatus.ready,
    this.note = '',
    this.failure,
  });

  /// The entry being viewed/edited, seeding [amountMinor]/[date]/[note] and
  /// carrying the `kind`/`id` the submit/delete calls need.
  final DebtEntry entry;

  final DebtEntryEditStatus status;

  /// A positive magnitude — the sign is re-derived from `entry.kind` (or, for
  /// a manual adjustment, from its own existing sign) by `UpdateDebtEntry`,
  /// never held here.
  final int amountMinor;

  final DateTime date;
  final String note;

  /// The debt's balance right after this entry (newest-first running balance
  /// already resolved by `DebtDetailCubit._runningBalances`; never re-derived
  /// here). Read-only in both variants — shown as the "Saldo después" row.
  final int runningMinor;

  final Failure? failure;

  /// `false` only for an `interestAccrual` (see class doc).
  bool get editable => entry.kind != DebtEntryKind.interestAccrual;

  bool get isSaving => status == DebtEntryEditStatus.saving;

  bool get isDeleting => status == DebtEntryEditStatus.deleting;

  bool get canSubmit => editable && amountMinor > 0 && !isSaving && !isDeleting;

  bool get canDelete => !isSaving && !isDeleting;

  DebtEntryEditState copyWith({
    DebtEntryEditStatus? status,
    int? amountMinor,
    DateTime? date,
    String? note,
    Failure? Function()? failure,
  }) =>
      DebtEntryEditState(
        entry: entry,
        status: status ?? this.status,
        amountMinor: amountMinor ?? this.amountMinor,
        date: date ?? this.date,
        note: note ?? this.note,
        runningMinor: runningMinor,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props =>
      [entry, status, amountMinor, date, note, runningMinor, failure];
}
