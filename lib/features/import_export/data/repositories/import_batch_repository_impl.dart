import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/entities/undo_summary.dart';
import '../../domain/repositories/import_batch_repository.dart';
import '../datasources/import_batches_local_datasource.dart';
import '../models/import_batch_mapper.dart';

/// Drift implementation of [ImportBatchRepository] (HU-08).
@LazySingleton(as: ImportBatchRepository)
class ImportBatchRepositoryImpl implements ImportBatchRepository {
  const ImportBatchRepositoryImpl(this._local, this._crash);

  final ImportBatchesLocalDatasource _local;
  final CrashReporter _crash;

  @override
  Stream<Result<List<ImportBatch>>> watchBatches() => _local
      .watchBatches()
      .map<Result<List<ImportBatch>>>(
        (rows) => Right(rows.map(ImportBatchMapper.toEntity).toList()),
      )
      .transform(
        StreamTransformer<Result<List<ImportBatch>>, Result<List<ImportBatch>>>
            .fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(error, stackTrace, context: 'import batches stream'),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'import batches stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );

  @override
  FutureResult<UndoSummary> undoBatch(String batchId) async {
    try {
      final batch = await _local.getBatch(batchId);
      if (batch == null) {
        return Left(NotFoundFailure('import batch "$batchId" does not exist'));
      }
      if (batch.revertedAt != null) {
        return Left(
          ValidationFailure('import batch "$batchId" was already reverted'),
        );
      }
      final summary = await _local.undoBatch(batchId);
      return Right(summary);
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'undo import batch');
      return Left(
        DatabaseFailure('could not revert import batch', cause: e, stackTrace: st),
      );
    }
  }
}
