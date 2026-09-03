import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_message.dart';
import '../repositories/ai_history_repository.dart';

/// Streams a thread, oldest first.
@injectable
class WatchAiMessages {
  const WatchAiMessages(this._repository);

  final AiHistoryRepository _repository;

  Stream<Result<List<AiMessage>>> call(String conversationId) =>
      _repository.watchMessages(conversationId);
}
