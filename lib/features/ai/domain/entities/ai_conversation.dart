import 'package:equatable/equatable.dart';

/// One thread in the assistant's history list, as opposed to `AiMessage`
/// which is a single bubble inside a thread.
///
/// There is no `ai_conversations` table (see `AiMessages` in
/// `app_database.dart`): a conversation is inferred by grouping messages on
/// their shared `conversationId`, so this entity is always derived, never
/// stored as-is.
class AiConversation extends Equatable {
  const AiConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;

  /// Derived from the thread's **first** user message, truncated to a
  /// reasonable length, so the title a user recognizes in the list never
  /// shifts while they keep chatting in that thread.
  ///
  /// `null` when the thread has no user message at all — every real thread
  /// has one (the first `append` is always the user's), so this only covers
  /// a malformed or partially-deleted row. `domain` does not invent user
  /// facing copy for that case; `presentation` is expected to substitute an
  /// `AppLocalizations` string when this is `null`.
  final String? title;

  /// `createdAt` of the most recent message in the thread.
  final DateTime updatedAt;

  final int messageCount;

  @override
  List<Object?> get props => [id, title, updatedAt, messageCount];
}
