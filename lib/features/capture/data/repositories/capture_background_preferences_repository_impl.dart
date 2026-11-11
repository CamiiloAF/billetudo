import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/capture_background_preferences_repository.dart';
import '../datasources/capture_background_preference_datasource.dart';

/// Implementation of [CaptureBackgroundPreferencesRepository] over local
/// preferences.
///
/// Unlike the one-shot capture offer, reads here **do not invent a value**: a
/// failed read returns a `Left`, and `GetCaptureBackgroundHealth` turns that
/// into "nothing to show". Pretending the card was snoozed when the read broke
/// would hide a real problem; pretending it was never snoozed would nag a user
/// who already said "Ahora no". Only the caller knows which mistake is cheaper,
/// so the repository stays honest.
@LazySingleton(as: CaptureBackgroundPreferencesRepository)
class CaptureBackgroundPreferencesRepositoryImpl
    implements CaptureBackgroundPreferencesRepository {
  const CaptureBackgroundPreferencesRepositoryImpl(this._prefs, this._crash);

  final CaptureBackgroundPreferenceDatasource _prefs;
  final CrashReporter _crash;

  @override
  FutureResult<DateTime?> configuredAt() async {
    try {
      return Right(await _prefs.readConfiguredAt());
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture background read');
      return Left(
        UnexpectedFailure(
          'capture background configured_at read failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<DateTime?> snoozedUntil() async {
    try {
      return Right(await _prefs.readSnoozeUntil());
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture background read');
      return Left(
        UnexpectedFailure(
          'capture background snooze_until read failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> markConfigured(DateTime at) async {
    try {
      await _prefs.writeConfiguredAt(at);
      return const Right(unit);
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture background write');
      return Left(
        UnexpectedFailure(
          'capture background configured_at write failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> snoozeUntil(DateTime until) async {
    try {
      await _prefs.writeSnoozeUntil(until);
      return const Right(unit);
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture background write');
      return Left(
        UnexpectedFailure(
          'capture background snooze_until write failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
