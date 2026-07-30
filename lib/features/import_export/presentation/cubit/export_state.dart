import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/export_scope.dart';

enum ExportRunStatus { idle, running, done, cancelled, error }

/// Export flow (HU-01/HU-02, `zFLrC`/`h6ZQQw`/`calDR`): choose what to
/// export, optionally filtered, and hand the result to the share sheet.
class ExportState extends Equatable {
  const ExportState({
    this.scope = const ExportScope(),
    this.hasAnyTransactions = true,
    this.runStatus = ExportRunStatus.idle,
    this.processed = 0,
    this.total = 0,
    this.failure,
    this.resultFilePath,
  });

  final ExportScope scope;

  /// `false` renders the empty variant (`calDR`) instead of the picker.
  final bool hasAnyTransactions;

  final ExportRunStatus runStatus;
  final int processed;
  final int total;
  final Failure? failure;

  /// Set once the write finishes — the page reacts to it by opening the
  /// share sheet, then clears it.
  final String? resultFilePath;

  bool get isRunning => runStatus == ExportRunStatus.running;

  ExportState copyWith({
    ExportScope? scope,
    bool? hasAnyTransactions,
    ExportRunStatus? runStatus,
    int? processed,
    int? total,
    Failure? failure,
    String? resultFilePath,
    bool clearResult = false,
  }) =>
      ExportState(
        scope: scope ?? this.scope,
        hasAnyTransactions: hasAnyTransactions ?? this.hasAnyTransactions,
        runStatus: runStatus ?? this.runStatus,
        processed: processed ?? this.processed,
        total: total ?? this.total,
        failure: failure,
        resultFilePath: clearResult ? null : (resultFilePath ?? this.resultFilePath),
      );

  @override
  List<Object?> get props => [
        scope,
        hasAnyTransactions,
        runStatus,
        processed,
        total,
        failure,
        resultFilePath,
      ];
}
