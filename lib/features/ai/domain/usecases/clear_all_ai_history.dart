import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/ai_history_repository.dart';

/// Erases every thread. Irreversible, same as `ClearAiHistory` for a single
/// thread.
@injectable
class ClearAllAiHistory {
  const ClearAllAiHistory(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<Unit> call() => _repository.clearAll();
}
