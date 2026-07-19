import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_occurrence.dart';

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

  /// The occurrence as it stands after a successful save, so the caller can
  /// offer "Deshacer" (criterion 10) by id.
  final ScheduledPaymentOccurrence? saved;

  final Failure? failure;

  bool get isSaving => status == SnoozeSheetStatus.saving;

  SnoozeSheetState copyWith({
    DateTime? selectedDate,
    SnoozeSheetStatus? status,
    ScheduledPaymentOccurrence? saved,
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
