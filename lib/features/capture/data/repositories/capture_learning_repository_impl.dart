import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../domain/repositories/capture_learning_repository.dart';
import '../datasources/merchant_learning_local_datasource.dart';

/// Drift implementation of [CaptureLearningRepository] over
/// `MerchantCategoryLearning`.
///
/// `updatedAt` is stamped here on every write, and forgetting is a physical
/// delete: a "forgotten" association that is only hidden would keep syncing
/// and would still be there in a backup.
@LazySingleton(as: CaptureLearningRepository)
class CaptureLearningRepositoryImpl implements CaptureLearningRepository {
  const CaptureLearningRepositoryImpl(this._local, this._crash);

  final MerchantLearningLocalDatasource _local;
  final CrashReporter _crash;

  @override
  FutureResult<Unit> learnMerchantCategory({
    required String merchantKey,
    required String categoryId,
  }) =>
      _guard(
        () => _local.runInTransaction(() async {
          final now = DateTime.now();
          final existing = await _local.getByMerchantKey(merchantKey);
          if (existing == null) {
            await _local.insertLearning(
              db.MerchantCategoryLearningCompanion.insert(
                merchantKey: merchantKey,
                categoryId: categoryId,
                createdAt: Value(now),
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );
            return const Right(unit);
          }
          // The user's latest decision wins: picking a different category
          // rewrites the association and restarts its count, instead of
          // leaving the old one entrenched by its history.
          final sameCategory = existing.categoryId == categoryId;
          await _local.updateLearning(
            existing.id,
            db.MerchantCategoryLearningCompanion(
              categoryId: Value(categoryId),
              hitCount: Value(sameCategory ? existing.hitCount + 1 : 1),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
          );
          return const Right(unit);
        }),
      );

  @override
  FutureResult<String?> suggestedCategoryFor(String merchantKey) =>
      _guard(() async {
        final categoryId = await _local.suggestedCategoryFor(merchantKey);
        return Right(categoryId);
      });

  @override
  FutureResult<Unit> forgetMerchant(String merchantKey) => _guard(() async {
        await _local.deleteByMerchantKey(merchantKey);
        return const Right(unit);
      });

  @override
  FutureResult<Unit> forgetAllLearning() => _guard(() async {
        await _local.deleteAll();
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture learning query');
      return Left(
        DatabaseFailure(
          'capture learning query failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
