import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/manual_movement_attempt_repository.dart';
import '../datasources/manual_movement_attempt_preference_datasource.dart';

/// [ManualMovementAttemptRepository] over local preferences.
///
/// A failed read is treated as zero attempts (the counter is a nudge, not a
/// gate), and a failed write is reported but does not block the `+` button:
/// the worst case is the tutorial being due one tap later. Never throws.
@LazySingleton(as: ManualMovementAttemptRepository)
class ManualMovementAttemptRepositoryImpl
    implements ManualMovementAttemptRepository {
  const ManualMovementAttemptRepositoryImpl(this._prefs, this._crash);

  final ManualMovementAttemptPreferenceDatasource _prefs;
  final CrashReporter _crash;

  @override
  FutureResult<int> registerAttempt() async {
    try {
      final attempts = await _prefs.readAttempts() + 1;
      await _prefs.writeAttempts(attempts);
      return Right(attempts);
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'manual movement attempt write');
      return Left(
        UnexpectedFailure(
          'manual movement attempt write failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
