import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/ai_client_context.dart';
import '../../domain/entities/ai_report.dart';
import '../../domain/usecases/report_ai_message.dart';
import 'ai_report_state.dart';

/// Drives the "Reportar mensaje" sheet: one reason (required), one optional
/// comment, one write. No local queue, no retry loop — [submit] either
/// files the report or tells the caller it could not, same contract as
/// [ReportAiMessage] itself.
@injectable
class AiReportCubit extends Cubit<AiReportState> {
  AiReportCubit(this._reportAiMessage, this._clientContext)
      : super(const AiReportState());

  final ReportAiMessage _reportAiMessage;
  final AiClientContextProvider _clientContext;

  void reasonSelected(AiReportReason reason) =>
      emit(state.copyWith(reason: reason, clearFailure: true));

  void commentChanged(String comment) => emit(state.copyWith(comment: comment));

  /// [reportedText] is the assistant message being reported, verbatim —
  /// never the conversation around it (see [AiReport]'s own doc).
  Future<void> submit({
    required String reportedText,
    String? conversationId,
  }) async {
    final reason = state.reason;
    if (reason == null || state.isSubmitting) {
      return;
    }
    emit(
      state.copyWith(status: AiReportStatus.submitting, clearFailure: true),
    );
    final clientVersion = (await _clientContext.resolve()).clientVersion;
    final comment = state.comment?.trim();
    final result = await _reportAiMessage(
      AiReport(
        reason: reason,
        reportedText: reportedText,
        clientVersion: clientVersion,
        conversationId: conversationId,
        comment: comment == null || comment.isEmpty ? null : comment,
      ),
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(status: AiReportStatus.failure, failure: failure));
      case Right():
        emit(state.copyWith(status: AiReportStatus.submitted));
    }
  }
}
