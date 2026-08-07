import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/backup_header.dart';
import '../entities/cancellation_token.dart';
import '../entities/progress_callback.dart';
import '../repositories/backup_repository.dart';

/// HU-03: writes a full `.billetudo.json` copy at `outputPath`. Works
/// whether or not the upload queue is caught up — it only reads the local
/// database (§"Recomendar la copia cuando la nube no está al día").
@injectable
class CreateFullBackup {
  const CreateFullBackup(this._repository);

  final BackupRepository _repository;

  FutureResult<BackupHeader> call({
    required String outputPath,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) =>
      _repository.createFullBackup(
        outputPath: outputPath,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
}
