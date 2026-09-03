import '../../../../core/error/result.dart';

/// The local link between a Home AI insight chip and the thread it started
/// (`AiInsightConversations`, local-only). `insightType` is an opaque string
/// key here — `HomeAiInsightType.name` — since this feature's domain must not
/// depend on Home's; the enum lives on the caller's side of every method.
abstract class AiInsightConversationRepository {
  /// The current `conversationId` linked to [insightType], or `null` when the
  /// user has never started a conversation from that specific chip.
  FutureResult<String?> latestConversationIdFor(String insightType);

  /// Records that [conversationId] was just started from the [insightType]
  /// chip. Append-only — see the table's own doc comment.
  FutureResult<Unit> link({
    required String insightType,
    required String conversationId,
  });
}
