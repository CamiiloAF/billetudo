import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/snooze_outcome.dart';

enum SnoozeSheetStatus { ready, saving, saved, failure }

/// State of the Posponer sheet (HU-07): a single date picker with a floor of
/// `max(fecha original, hoy)` (criterion 10).
class SnoozeSheetState extends Equatable {
  const SnoozeSheetState({
    required this.minDate,
    required this.selectedDate,
    this.status = SnoozeSheetStatus.ready,
    this.saved,
    this.failure,
  });

  final DateTime minDate;
  final DateTime selectedDate;
  final SnoozeSheetStatus status;

  /// The snooze result after a successful save — the resulting occurrence plus
  /// the pre-snooze state — so the caller can offer "Deshacer" (criterion 10)
  /// and reverse exactly one step.
  final SnoozeOutcome? saved;

  final Failure? failure;

  bool get isSaving => status == SnoozeSheetStatus.saving;

  SnoozeSheetState copyWith({
    DateTime? selectedDate,
    SnoozeSheetStatus? status,
    SnoozeOutcome? saved,
    Failure? failure,
  }) =>
      SnoozeSheetState(
        minDate: minDate,
        selectedDate: selectedDate ?? this.selectedDate,
        status: status ?? this.status,
        saved: saved ?? this.saved,
        failure: failure,
      );

  @override
  List<Object?> get props => [minDate, selectedDate, status, saved, failure];
}
