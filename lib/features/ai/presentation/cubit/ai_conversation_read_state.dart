import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_message.dart';

/// The three states `AiConversationReadPage` renders, same shape as
/// `AiHistoryState` — this is a read of a single thread rather than a list.
enum AiConversationReadStatus { loading, ready, failure }

class AiConversationReadState extends Equatable {
  const AiConversationReadState({
    this.status = AiConversationReadStatus.loading,
    this.messages = const <AiMessage>[],
    this.accountNames = const <String, String>{},
    this.debtNames = const <String, String>{},
    this.failure,
  });

  final AiConversationReadStatus status;

  /// Oldest first, as `WatchAiMessages` streams them.
  final List<AiMessage> messages;

  /// Same purpose as `AiChatState.accountNames`: lets a persisted
  /// `AiProposalCard` name a real account instead of a bare id.
  final Map<String, String> accountNames;

  /// Same purpose as `AiChatState.debtNames`.
  final Map<String, String> debtNames;

  final Failure? failure;

  AiConversationReadState copyWith({
    AiConversationReadStatus? status,
    List<AiMessage>? messages,
    Map<String, String>? accountNames,
    Map<String, String>? debtNames,
    Failure? failure,
  }) =>
      AiConversationReadState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        accountNames: accountNames ?? this.accountNames,
        debtNames: debtNames ?? this.debtNames,
        failure: failure ?? this.failure,
      );

  @override
  List<Object?> get props =>
      [status, messages, accountNames, debtNames, failure];
}
