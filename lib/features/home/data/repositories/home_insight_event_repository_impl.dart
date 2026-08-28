import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/home_ai_insight.dart';
import '../../domain/entities/home_insight_event_snapshot.dart';
import '../../domain/repositories/home_insight_event_repository.dart';
import '../datasources/home_insight_event_local_datasource.dart';

/// Drift implementation of [HomeInsightEventRepository]. Same guard shape as
/// `AiInsightConversationRepositoryImpl`.
@LazySingleton(as: HomeInsightEventRepository)
class HomeInsightEventRepositoryImpl implements HomeInsightEventRepository {
  const HomeInsightEventRepositoryImpl(this._local, this._crash);

  static const _kindShown = 'shown';
  static const _kindDismissed = 'dismissed';

  final HomeInsightEventLocalDatasource _local;
  final CrashReporter _crash;

  @override
  Stream<Result<HomeInsightEventSnapshot>> watch() => _guardStream(
        _local.watchAll().map((rows) => Right(_toSnapshot(rows))),
      );

  @override
  FutureResult<Unit> recordShown(HomeAiInsightType type) => _guard(() async {
        await _local.insertEvent(
          insightType: type.name,
          kind: _kindShown,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> dismiss(HomeAiInsightType type) => _guard(() async {
        await _local.insertEvent(
          insightType: type.name,
          kind: _kindDismissed,
        );
        return const Right(unit);
      });

  /// Reduces the append-only ledger into "the latest `occurredAt` per
  /// `(insightType, kind)`" — rows arrive in no particular order, so every
  /// row is compared against whatever is already in the accumulator instead
  /// of assuming the last one wins.
  HomeInsightEventSnapshot _toSnapshot(List<HomeInsightEvent> rows) {
    final dismissedAt = <HomeAiInsightType, DateTime>{};
    final lastShownAt = <HomeAiInsightType, DateTime>{};
    for (final row in rows) {
      final type = _typeFrom(row.insightType);
      if (type == null) {
        continue;
      }
      final occurredAt =
          DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true);
      final target = switch (row.kind) {
        _kindDismissed => dismissedAt,
        _kindShown => lastShownAt,
        _ => null,
      };
      if (target == null) {
        continue;
      }
      final current = target[type];
      if (current == null || occurredAt.isAfter(current)) {
        target[type] = occurredAt;
      }
    }
    return HomeInsightEventSnapshot(
      dismissedAt: dismissedAt,
      lastShownAt: lastShownAt,
    );
  }

  /// `null` for a row whose `insightType` does not match any current
  /// `HomeAiInsightType` — e.g. a value written by a future app version and
  /// read back by this one. Skipped rather than crashing the stream.
  HomeAiInsightType? _typeFrom(String raw) {
    for (final value in HomeAiInsightType.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'home insight event query');
      return Left(
        DatabaseFailure(
          'home insight event query failed',
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
                context: 'home insight events stream',
              ),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'home insight events stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );
}
