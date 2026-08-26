import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_conversation.dart';
import '../repositories/ai_history_repository.dart';

/// Streams every thread that has at least one message, most recently updated
/// first — the history screen's list.
@injectable
class WatchAiConversations {
  const WatchAiConversations(this._repository);

  final AiHistoryRepository _repository;

  Stream<Result<List<AiConversation>>> call() =>
      _repository.watchConversations();
}
