import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_insight_conversation_repository.dart';

/// Records that a Home AI insight chip just started `conversationId`. Must be
/// called at the exact moment the user starts that conversation from that
/// chip — never before, and never speculatively — so a chip whose thread was
/// never actually opened keeps saying "iniciar conversación" instead of
/// jumping straight to "continuar".
@injectable
class LinkInsightToConversation {
  const LinkInsightToConversation(this._repository);

  final AiInsightConversationRepository _repository;

  FutureResult<Unit> call({
    required String insightType,
    required String conversationId,
  }) =>
      _repository.link(
          insightType: insightType, conversationId: conversationId);
}
