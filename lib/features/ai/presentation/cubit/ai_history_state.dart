import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_conversation.dart';

/// The three states the history list renders (`billetudo.pen` `EGwSs` base,
/// `bDdyA` loading skeleton, `JZVFV` error).
enum AiHistoryStatus { loading, ready, failure }

class AiHistoryState extends Equatable {
  const AiHistoryState({
    this.status = AiHistoryStatus.loading,
    this.conversations = const <AiConversation>[],
    this.failure,
  });

  final AiHistoryStatus status;
  final List<AiConversation> conversations;
  final Failure? failure;

  bool get isEmpty => status == AiHistoryStatus.ready && conversations.isEmpty;

  AiHistoryState copyWith({
    AiHistoryStatus? status,
    List<AiConversation>? conversations,
    Failure? failure,
  }) =>
      AiHistoryState(
        status: status ?? this.status,
        conversations: conversations ?? this.conversations,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, conversations, failure];
}
