import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/tutorial_key.dart';
import '../../domain/repositories/tutorials_repository.dart';
import '../datasources/tutorial_views_local_datasource.dart';

/// Drift implementation of [TutorialsRepository] over `TutorialViews` and
/// `AppSettings.showHelpOnSectionEntry`. Stamps `updatedAt` on every write —
/// see [TutorialViewsLocalDatasource].
@LazySingleton(as: TutorialsRepository)
class TutorialsRepositoryImpl implements TutorialsRepository {
  const TutorialsRepositoryImpl(this._local);

  final TutorialViewsLocalDatasource _local;

  @override
  FutureResult<bool> hasSeen(TutorialKey key) async {
    try {
      final seen = await _local.hasSeen(key);
      return Right(seen);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to read tutorial seen status',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> markSeen(TutorialKey key) async {
    try {
      await _local.markSeen(key, now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to mark tutorial as seen',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<Unit> resetAll() async {
    try {
      await _local.deleteAll();
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to reset tutorial seen registry',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<Result<bool>> watchHelpEnabled() => _local
      .watchHelpEnabled()
      .map<Result<bool>>(Right.new)
      .transform(_guardStream());

  @override
  FutureResult<Unit> setHelpEnabled({required bool enabled}) async {
    try {
      await _local.setHelpEnabled(enabled: enabled, now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to update help preference',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  StreamTransformer<Result<bool>, Result<bool>> _guardStream() =>
      StreamTransformer<Result<bool>, Result<bool>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) => sink.add(
          Left(
            DatabaseFailure(
              'help preference stream failed',
              cause: error,
              stackTrace: stackTrace,
            ),
          ),
        ),
      );
}
