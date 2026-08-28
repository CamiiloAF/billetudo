import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/home_ai_insight.dart';
import '../repositories/home_insight_event_repository.dart';

/// "Ahora no": persists that [HomeAiInsightType] was dismissed, so it stays
/// out of the AI card for the rest of the current calendar month even as new
/// transactions keep recomputing `WatchHomeAiInsight` — bug fix, see
/// `HomeInsightEventRepository`'s doc comment.
@injectable
class DismissHomeInsight {
  const DismissHomeInsight(this._repository);

  final HomeInsightEventRepository _repository;

  FutureResult<Unit> call(HomeAiInsightType type) => _repository.dismiss(type);
}
