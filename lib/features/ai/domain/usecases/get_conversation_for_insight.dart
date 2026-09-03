import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_insight_conversation_repository.dart';

/// The conversation already linked to a Home AI insight chip, or `null` when
/// the user has never started one from that specific chip yet — the signal
/// `AiCardInsight` uses to decide between its "iniciar conversación" and
/// "continuar conversación" copy/destination (bug fix: the chip used to
/// always reopen whatever conversation was most recently active, regardless
/// of which insight it came from).
///
/// `insightType` is `HomeAiInsightType.name`, passed as plain text since this
/// feature's domain must not depend on Home's — see
/// `AiInsightConversationRepository`'s own doc.
@injectable
class GetConversationForInsight {
  const GetConversationForInsight(this._repository);

  final AiInsightConversationRepository _repository;

  FutureResult<String?> call(String insightType) =>
      _repository.latestConversationIdFor(insightType);
}
