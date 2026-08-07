import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/backup_header.dart';
import '../../domain/entities/restore_mode.dart';
import '../../domain/entities/restore_summary.dart';

enum RestoreStep { pickFile, summary, replaceAllConfirm, running, done, error }

/// HU-04: validate → summary → mode choice (with escalated confirmation for
/// `replaceAll`) → restore.
class RestoreState extends Equatable {
  const RestoreState({
    this.step = RestoreStep.pickFile,
    this.filePath,
    this.header,
    this.mode = RestoreMode.merge,
    this.replaceAllAcknowledged = false,
    this.summary,
    this.failure,
    this.processed = 0,
    this.total = 0,
  });

  final RestoreStep step;
  final String? filePath;
  final BackupHeader? header;
  final RestoreMode mode;

  /// The escalated-confirmation checkbox for `RestoreMode.replaceAll`
  /// (HU-04: never a single "OK" for a destructive, irreversible action).
  final bool replaceAllAcknowledged;

  final RestoreSummary? summary;
  final Failure? failure;

  /// Tables merged so far / total tables (HU-04: "una sola transacción de
  /// base de datos" — this counts tables, not rows, same granularity as
  /// `SaveCopyState`).
  final int processed;
  final int total;

  bool get canConfirm =>
      mode == RestoreMode.merge || replaceAllAcknowledged;

  RestoreState copyWith({
    RestoreStep? step,
    String? filePath,
    BackupHeader? header,
    RestoreMode? mode,
    bool? replaceAllAcknowledged,
    RestoreSummary? summary,
    Failure? failure,
    int? processed,
    int? total,
  }) =>
      RestoreState(
        step: step ?? this.step,
        filePath: filePath ?? this.filePath,
        header: header ?? this.header,
        mode: mode ?? this.mode,
        replaceAllAcknowledged: replaceAllAcknowledged ?? this.replaceAllAcknowledged,
        summary: summary ?? this.summary,
        failure: failure,
        processed: processed ?? this.processed,
        total: total ?? this.total,
      );

  @override
  List<Object?> get props => [
        step,
        filePath,
        header,
        mode,
        replaceAllAcknowledged,
        summary,
        failure,
        processed,
        total,
      ];
}
