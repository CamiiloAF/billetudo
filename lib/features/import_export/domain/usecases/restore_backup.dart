import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/progress_callback.dart';
import '../entities/restore_mode.dart';
import '../entities/restore_summary.dart';
import '../repositories/backup_repository.dart';
import 'parse_backup_header.dart';

/// HU-04: restores the copy at `inputPath` per `mode`. Delegates the
/// cabecera/schema gate to [ParseBackupHeader] first — never even opens a
/// transaction against a copy this build should refuse.
@injectable
class RestoreBackup {
  const RestoreBackup(this._repository, this._parseHeader);

  final BackupRepository _repository;
  final ParseBackupHeader _parseHeader;

  FutureResult<RestoreSummary> call({
    required String inputPath,
    required RestoreMode mode,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final headerResult = await _parseHeader(inputPath);
    return headerResult.fold(
      Left.new,
      (_) => _repository.restoreBackup(
        inputPath: inputPath,
        mode: mode,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      ),
    );
  }
}
