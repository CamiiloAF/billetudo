import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/home_ai_insight.dart';
import '../repositories/home_insight_event_repository.dart';

/// Records that the AI card just started showing [HomeAiInsightType] —
/// feeds the 24h cooldown `WatchHomeAiInsight` enforces per type. Callers
/// must only invoke this on the transition into showing a type (see
/// `HomeInsightEventRepository.recordShown`'s doc comment).
@injectable
class RecordHomeInsightShown {
  const RecordHomeInsightShown(this._repository);

  final HomeInsightEventRepository _repository;

  FutureResult<Unit> call(HomeAiInsightType type) =>
      _repository.recordShown(type);
}
