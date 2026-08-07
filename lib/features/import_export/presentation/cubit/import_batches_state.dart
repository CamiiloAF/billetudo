import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/entities/undo_summary.dart';

enum ImportBatchesStatus { loading, ready, failure }

/// HU-08 history (`tJhwB`/`tiCoZ`).
class ImportBatchesState extends Equatable {
  const ImportBatchesState({
    this.status = ImportBatchesStatus.loading,
    this.batches = const [],
    this.failure,
    this.lastUndoSummary,
  });

  final ImportBatchesStatus status;
  final List<ImportBatch> batches;
  final Failure? failure;

  /// Set right after a successful undo, for the confirmation sheet's own
  /// after-the-fact summary.
  final UndoSummary? lastUndoSummary;

  bool get isEmpty => status == ImportBatchesStatus.ready && batches.isEmpty;

  ImportBatchesState copyWith({
    ImportBatchesStatus? status,
    List<ImportBatch>? batches,
    Failure? failure,
    UndoSummary? lastUndoSummary,
    bool clearLastUndoSummary = false,
  }) =>
      ImportBatchesState(
        status: status ?? this.status,
        batches: batches ?? this.batches,
        failure: failure,
        lastUndoSummary:
            clearLastUndoSummary ? null : (lastUndoSummary ?? this.lastUndoSummary),
      );

  @override
  List<Object?> get props => [status, batches, failure, lastUndoSummary];
}
