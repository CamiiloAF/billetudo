import '../../../../core/error/result.dart';
import '../entities/ai_report.dart';

/// Sends a report of generated content to our own servers (Play's
/// AI-Generated Content policy — see [AiReport] for why this one write is
/// allowed to leave the device).
///
/// Requires a signed-in session: the row is keyed by `user_id` and RLS only
/// accepts an insert of your own. There is no local queue and no retry — a
/// report that could not be sent is told so, rather than silently held on a
/// device whose owner believes it was filed.
abstract class AiReportRepository {
  FutureResult<Unit> report(AiReport report);
}
