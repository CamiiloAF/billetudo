import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_history_repository.dart';

/// Resolves the thread to show when the assistant screen opens: the last one
/// if it exists, a brand-new one otherwise.
///
/// The only repository method of this feature with no use case of its own —
/// every sibling in `usecases/` wraps one repository call, and presentation
/// must never reach a repository directly (`CLAUDE.md`). Added alongside the
/// rest of `presentation/` rather than reworking `data/`/`domain/`'s already
/// tested surface.
@injectable
class ResumeOrCreateAiConversation {
  const ResumeOrCreateAiConversation(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<String> call() => _repository.resumeOrCreateConversation();
}
