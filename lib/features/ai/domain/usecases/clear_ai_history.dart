import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_history_repository.dart';

/// Erases a thread.
@injectable
class ClearAiHistory {
  const ClearAiHistory(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<Unit> call(String conversationId) =>
      _repository.clear(conversationId);
}
