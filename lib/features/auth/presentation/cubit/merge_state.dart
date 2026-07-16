import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/merge_summary.dart';

enum MergeStatus { loading, ready, failure }

/// State of the "Tus datos están a salvo" confirmation (`vexqA`, HU-04).
class MergeState extends Equatable {
  const MergeState(
      {this.status = MergeStatus.loading, this.summary, this.failure});

  final MergeStatus status;
  final MergeSummary? summary;
  final Failure? failure;

  MergeState copyWith({
    MergeStatus? status,
    MergeSummary? summary,
    Failure? failure,
  }) =>
      MergeState(
        status: status ?? this.status,
        summary: summary ?? this.summary,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, summary, failure];
}
