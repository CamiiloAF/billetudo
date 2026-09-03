import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_history_repository.dart';

/// Always opens a brand-new thread, never the last one — the "start fresh"
/// action from the history screen. App launch instead calls
/// `AiHistoryRepository.resumeOrCreateConversation()` directly, which
/// deliberately reuses the last thread.
@injectable
class StartNewAiConversation {
  const StartNewAiConversation(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<String> call() => _repository.startNewConversation();
}
