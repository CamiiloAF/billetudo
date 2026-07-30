import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/backup_status_repository.dart';

/// Records that a local copy (HU-03) was just saved, so the hub's status row
/// reflects it after the write succeeds.
@injectable
class MarkBackupSaved {
  const MarkBackupSaved(this._repository);

  final BackupStatusRepository _repository;

  FutureResult<Unit> call(DateTime savedAt) =>
      _repository.setLastSavedAt(savedAt);
}
