import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/backup_status_repository.dart';
import '../datasources/backup_status_local_datasource.dart';

@LazySingleton(as: BackupStatusRepository)
class BackupStatusRepositoryImpl implements BackupStatusRepository {
  const BackupStatusRepositoryImpl(this._local, this._crash);

  final BackupStatusLocalDatasource _local;
  final CrashReporter _crash;

  @override
  FutureResult<DateTime?> getLastSavedAt() => _guard(() async {
        final value = await _local.getLastSavedAt();
        return Right(value);
      });

  @override
  FutureResult<Unit> setLastSavedAt(DateTime savedAt) => _guard(() async {
        await _local.setLastSavedAt(savedAt);
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'backup status');
      return Left(
        DatabaseFailure('backup status storage failed', cause: e, stackTrace: st),
      );
    }
  }
}
