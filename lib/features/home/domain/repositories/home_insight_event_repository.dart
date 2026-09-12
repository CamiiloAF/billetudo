import '../../../../core/error/result.dart';
import '../entities/home_ai_insight.dart';
import '../entities/home_insight_event_snapshot.dart';

/// The device-local ledger of when the Home AI card last showed or was
/// dismissed for each [HomeAiInsightType] — see `HomeInsightEvents`'s doc
/// comment in `core/database/app_database.dart` for why this exists and why
/// it is local-only.
///
/// [HomeAiInsightType.createBudget] must never be passed to [recordShown] or
/// [dismiss]: it is a forced state with no "Ahora no", not a dismissible or
/// coolable insight.
abstract class HomeInsightEventRepository {
  /// Live per-type dismissal/last-shown bookkeeping.
  Stream<Result<HomeInsightEventSnapshot>> watch();

  /// Records that the card just started showing [type] — call only on the
  /// transition into showing it, never on every recompute that keeps it
  /// showing (see `HomeCubit._onAiInsight`), or the 24h cooldown this feeds
  /// would defeat itself within the same session.
  FutureResult<Unit> recordShown(HomeAiInsightType type);

  /// Records the user tapping "Ahora no" on [type]. Excludes it from
  /// [HomeInsightEventSnapshot.dismissedAt]-based filtering for the rest of
  /// the current calendar month.
  FutureResult<Unit> dismiss(HomeAiInsightType type);
}
