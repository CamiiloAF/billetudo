import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/capture_offer_repository.dart';
import '../datasources/capture_offer_preference_datasource.dart';

/// Implementation of [CaptureOfferRepository] over local preferences.
///
/// A read that fails answers "already offered". Failing closed keeps a broken
/// preference store from re-offering the most invasive permission of the
/// phone on every single expense the user saves.
@LazySingleton(as: CaptureOfferRepository)
class CaptureOfferRepositoryImpl implements CaptureOfferRepository {
  const CaptureOfferRepositoryImpl(this._prefs, this._crash);

  final CaptureOfferPreferenceDatasource _prefs;
  final CrashReporter _crash;

  @override
  FutureResult<bool> hasBeenOffered() async {
    try {
      return Right(await _prefs.readOffered());
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture offer read');
      return const Right(true);
    }
  }

  @override
  FutureResult<Unit> markOffered() async {
    try {
      await _prefs.writeOffered();
      return const Right(unit);
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture offer write');
      return Left(
        UnexpectedFailure('capture offer write failed',
            cause: e, stackTrace: st),
      );
    }
  }
}
