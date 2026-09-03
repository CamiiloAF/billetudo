import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_report.dart';

enum AiReportStatus { editing, submitting, submitted, failure }

/// State of the "Reportar mensaje" sheet.
///
/// [reason] starts `null` on purpose: `G6uAwV` is the real default state in
/// production — no motive pre-selected, "Enviar" disabled until one is
/// picked (`canSubmit`).
class AiReportState extends Equatable {
  const AiReportState({
    this.reason,
    this.comment,
    this.status = AiReportStatus.editing,
    this.failure,
  });

  final AiReportReason? reason;

  /// The person's own words, trimmed. `null`/empty means no comment.
  final String? comment;

  final AiReportStatus status;
  final Failure? failure;

  bool get isSubmitting => status == AiReportStatus.submitting;

  bool get canSubmit => reason != null && !isSubmitting;

  AiReportState copyWith({
    AiReportReason? reason,
    String? comment,
    AiReportStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AiReportState(
        reason: reason ?? this.reason,
        comment: comment ?? this.comment,
        status: status ?? this.status,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [reason, comment, status, failure];
}
