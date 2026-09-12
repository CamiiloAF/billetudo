import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_message.dart';
import '../repositories/ai_history_repository.dart';

/// Appends a bubble to a thread.
@injectable
class AppendAiMessage {
  const AppendAiMessage(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<Unit> call(AiMessage message) => _repository.append(message);
}
