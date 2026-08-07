import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';

enum SaveCopyStatus { idle, running, done, cancelled, error }

/// HU-03 "Guardar una copia" (`d9wzVg`-pattern with `$teal`).
class SaveCopyState extends Equatable {
  const SaveCopyState({
    this.status = SaveCopyStatus.idle,
    this.processed = 0,
    this.total = 0,
    this.resultFilePath,
    this.savedAt,
    this.failure,
  });

  final SaveCopyStatus status;

  /// Tables written so far / total tables (HU-03: "streaming, tabla por
  /// tabla" — this counts tables, not rows).
  final int processed;
  final int total;

  final String? resultFilePath;

  /// The backup's `createdAt` once [SaveCopyStatus.done] is reached — what
  /// `SaveCopySheet.show` hands back to its caller so the hub's hero card can
  /// update without waiting for a full refresh.
  final DateTime? savedAt;

  final Failure? failure;

  SaveCopyState copyWith({
    SaveCopyStatus? status,
    int? processed,
    int? total,
    String? resultFilePath,
    bool clearResult = false,
    DateTime? savedAt,
    Failure? failure,
  }) =>
      SaveCopyState(
        status: status ?? this.status,
        processed: processed ?? this.processed,
        total: total ?? this.total,
        resultFilePath: clearResult ? null : (resultFilePath ?? this.resultFilePath),
        savedAt: savedAt ?? this.savedAt,
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, processed, total, resultFilePath, savedAt, failure];
}
