import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/ai_insight_conversation_repository.dart';
import '../datasources/ai_insight_conversation_local_datasource.dart';

/// Drift implementation of [AiInsightConversationRepository]. Same guard
/// shape as the rest of this feature's local repositories
/// (`AiHistoryRepositoryImpl`).
@LazySingleton(as: AiInsightConversationRepository)
class AiInsightConversationRepositoryImpl
    implements AiInsightConversationRepository {
  const AiInsightConversationRepositoryImpl(this._local, this._crash);

  final AiInsightConversationLocalDatasource _local;
  final CrashReporter _crash;

  @override
  FutureResult<String?> latestConversationIdFor(String insightType) =>
      _guard(() async {
        final id = await _local.latestConversationId(insightType);
        return Right(id);
      });

  @override
  FutureResult<Unit> link({
    required String insightType,
    required String conversationId,
  }) =>
      _guard(() async {
        await _local.insertLink(
          insightType: insightType,
          conversationId: conversationId,
        );
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(
        e,
        st,
        context: 'ai insight conversation query',
      );
      return Left(
        DatabaseFailure(
          'ai insight conversation query failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
