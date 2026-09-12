import '../../../../core/error/result.dart';
import '../entities/ai_action_proposal.dart';
import '../entities/ai_conversation.dart';
import '../entities/ai_message.dart';

/// The local transcript. The device owns it outright: the broker keeps no
/// copy, so losing this is losing the conversation.
abstract class AiHistoryRepository {
  /// Streams a thread, oldest first. Reactive because a user bubble is written
  /// before the network call and updated when it lands.
  Stream<Result<List<AiMessage>>> watchMessages(String conversationId);

  FutureResult<Unit> append(AiMessage message);

  /// Persists a card's new state so a confirmed proposal cannot be confirmed
  /// twice after the app is reopened.
  FutureResult<Unit> updateProposalStatus({
    required String messageId,
    required String proposalId,
    required AiProposalStatus status,
  });

  /// The id of the thread to show: the last one if it exists, a brand-new one
  /// otherwise. One call, because "read then maybe create" from presentation
  /// would race with itself on a fast relaunch.
  FutureResult<String> resumeOrCreateConversation();

  /// All threads that have at least one message, most recently updated first.
  Stream<Result<List<AiConversation>>> watchConversations();

  /// Always creates a brand-new thread id, never reuses the last one. This is
  /// what a "start fresh" action needs, as opposed to
  /// [resumeOrCreateConversation] (used at app launch, which deliberately
  /// reuses the last thread).
  FutureResult<String> startNewConversation();

  /// Empties a thread. Irreversible on purpose — there is no undo affordance
  /// for a transcript the user explicitly asked to erase.
  FutureResult<Unit> clear(String conversationId);

  /// Deletes every message in every thread. Irreversible, same as [clear].
  FutureResult<Unit> clearAll();
}
