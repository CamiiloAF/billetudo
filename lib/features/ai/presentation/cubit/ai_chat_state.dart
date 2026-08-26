import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_message.dart';

/// The four states the chat screen renders (`billetudo.pen`, `ueaIi`
/// base/`M2oLsq` thinking/`V7gvu` error).
enum AiChatStatus { loading, ready, thinking, error }

class AiChatState extends Equatable {
  const AiChatState({
    this.status = AiChatStatus.loading,
    this.conversationId,
    this.messages = const <AiMessage>[],
    this.draft = '',
    this.failure,
    this.accountNames = const <String, String>{},
  });

  final AiChatStatus status;
  final String? conversationId;

  /// Oldest first, as `WatchAiMessages` streams them.
  final List<AiMessage> messages;

  /// The composer's current text. Kept in state (not local widget state) so
  /// the Send button's `opacity:0.4`/`1` (`billetudo.pen`, `qnhSI`) can react
  /// to it from `BlocBuilder` alone.
  final String draft;

  final Failure? failure;

  /// `Account.id` → `Account.name`, for `AiProposalCard`'s transaction body to
  /// show a real account name instead of a bare id. Never a category-name
  /// equivalent: unlike accounts (`WatchAccounts`, a flat list already read
  /// for this purpose), category names would need a `WatchCategories(kind)`
  /// call per kind plus a tree flatten, which is not wired for display today
  /// — the transaction/category proposal bodies fall back to a generic label
  /// rather than fabricate a name.
  final Map<String, String> accountNames;

  bool get canSend =>
      draft.trim().isNotEmpty &&
      status != AiChatStatus.thinking &&
      status != AiChatStatus.loading;

  AiChatState copyWith({
    AiChatStatus? status,
    String? conversationId,
    List<AiMessage>? messages,
    String? draft,
    Failure? failure,
    bool clearFailure = false,
    Map<String, String>? accountNames,
  }) =>
      AiChatState(
        status: status ?? this.status,
        conversationId: conversationId ?? this.conversationId,
        messages: messages ?? this.messages,
        draft: draft ?? this.draft,
        failure: clearFailure ? null : (failure ?? this.failure),
        accountNames: accountNames ?? this.accountNames,
      );

  @override
  List<Object?> get props => [
        status,
        conversationId,
        messages,
        draft,
        failure,
        accountNames,
      ];
}
