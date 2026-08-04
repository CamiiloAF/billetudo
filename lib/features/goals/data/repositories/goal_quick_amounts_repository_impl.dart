import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/goal_quick_amount.dart';
import '../../domain/repositories/goal_quick_amounts_repository.dart';
import '../datasources/goal_quick_amounts_local_datasource.dart';
import '../models/goal_quick_amount_mapper.dart';

/// Drift implementation of [GoalQuickAmountsRepository]. Stamps `updatedAt`
/// on every write, same as the rest of the app.
@LazySingleton(as: GoalQuickAmountsRepository)
class GoalQuickAmountsRepositoryImpl implements GoalQuickAmountsRepository {
  const GoalQuickAmountsRepositoryImpl(this._local, this._crash);

  final GoalQuickAmountsLocalDatasource _local;
  final CrashReporter _crash;

  @override
  Stream<Result<List<GoalQuickAmount>>> watchQuickAmounts(String goalId) =>
      _guardStream(
        _local.watchQuickAmounts(goalId).map(
              (rows) =>
                  Right(rows.map(GoalQuickAmountMapper.toEntity).toList()),
            ),
      );

  @override
  FutureResult<GoalQuickAmount> createQuickAmount({
    required String goalId,
    required int amountMinor,
  }) =>
      _guard(() async {
        final row = await _local.insertQuickAmount(
          GoalQuickAmountMapper.toInsertCompanion(
            goalId: goalId,
            amountMinor: amountMinor,
            now: DateTime.now(),
          ),
        );
        return Right(GoalQuickAmountMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> deleteQuickAmount(String id) => _guard(() async {
        await _local.deleteQuickAmount(id);
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'goal quick amounts query');
      return Left(
        DatabaseFailure(
          'goal quick amounts query failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(
                error,
                stackTrace,
                context: 'goal quick amounts stream',
              ),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'goal quick amounts stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );
}
