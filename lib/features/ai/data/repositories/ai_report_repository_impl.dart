import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_report.dart';
import '../../domain/repositories/ai_report_repository.dart';
import '../datasources/ai_report_remote_datasource.dart';

/// Supabase implementation of [AiReportRepository].
///
/// Deliberately has **no** `CrashReporter`: a failed report is the one error
/// in this feature whose context is the reported message itself, and that text
/// is exactly what must not be uploaded anywhere it was not explicitly sent.
/// The failure travels back to the UI, which asks the person to retry.
@LazySingleton(as: AiReportRepository)
class AiReportRepositoryImpl implements AiReportRepository {
  const AiReportRepositoryImpl(this._remote);

  final AiReportRemoteDatasource _remote;

  @override
  FutureResult<Unit> report(AiReport report) async {
    try {
      await _remote.insertReport(<String, Object?>{
        'conversation_id': report.conversationId,
        // The enum names match the table's CHECK constraint exactly
        // (`offensive`, `wrong`, `harmful`, `privacy`, `other`). Renaming a
        // value on either side breaks the insert loudly, which is the right
        // failure mode for a closed list.
        'reason': report.reason.name,
        'reported_text': report.reportedText,
        'comment': report.comment,
        'client_version': report.clientVersion,
        // `status` is left to its default: the app never writes it, and there
        // is no update policy that would let it.
      });
      return const Right(unit);
    } on AiReportException catch (e) {
      if (e.isUnauthenticated) {
        return Left(
          AiFailure(
            'ai report rejected: no session to attribute it to',
            code: AiFailureCode.unauthenticated,
            cause: _sanitize(e.cause),
            stackTrace: e.stackTrace,
          ),
        );
      }
      return Left(
        NetworkFailure(
          'ai report could not be filed',
          cause: _sanitize(e.cause),
          stackTrace: e.stackTrace,
        ),
      );
    }
  }

  /// Keeps the original error's type and drops everything else.
  ///
  /// A rejected insert reports itself with Postgres' `DETAIL: Failing row
  /// contains (…)`, which for this table means the reported message inside the
  /// error. `CrashReporter.recordFailure` uploads `Failure.cause` verbatim, so
  /// the text has to be stripped here — the report was consented to, an
  /// upload to Sentry was not.
  Object? _sanitize(Object? error) => error == null
      ? null
      : StateError('ai report failed with ${error.runtimeType}');
}
