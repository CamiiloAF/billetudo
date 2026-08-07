import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/backup_header.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/progress_callback.dart';
import '../../domain/entities/restore_mode.dart';
import '../../domain/entities/restore_summary.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_json_datasource.dart';

/// Drift + JSON implementation of [BackupRepository] (HU-03/HU-04).
@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._local);

  final BackupJsonDatasource _local;

  @override
  FutureResult<BackupHeader> createFullBackup({
    required String outputPath,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final result = await _local.createFullBackup(
      outputPath,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
    return result.map(_toHeader);
  }

  @override
  FutureResult<BackupHeader> parseBackupHeader(String inputPath) async {
    final result = await _local.parseHeader(inputPath);
    return result.map(_toHeader);
  }

  @override
  FutureResult<RestoreSummary> restoreBackup({
    required String inputPath,
    required RestoreMode mode,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final result = await _local.restore(
      inputPath,
      mode: mode,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
    return result.map(
      (byTable) => RestoreSummary(
        mode: mode,
        createdByTable: {
          for (final entry in byTable.entries) entry.key: entry.value.created,
        },
        updatedByTable: {
          for (final entry in byTable.entries) entry.key: entry.value.updated,
        },
        skippedByTable: {
          for (final entry in byTable.entries) entry.key: entry.value.skipped,
        },
      ),
    );
  }

  BackupHeader _toHeader(Map<String, dynamic> raw) => BackupHeader(
        formatVersion: raw['formatVersion'] as int,
        schemaVersion: raw['schemaVersion'] as int,
        appVersion: raw['appVersion'] as String,
        createdAt: raw['createdAt'] as DateTime,
        rowCountsByTable: Map<String, int>.from(
          raw['rowCountsByTable'] as Map<String, dynamic>,
        ),
      );
}
