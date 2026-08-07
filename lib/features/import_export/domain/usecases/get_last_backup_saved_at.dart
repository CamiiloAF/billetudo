import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/backup_status_repository.dart';

/// The hub's "Última copia: <fecha>" / "Aún no has guardado una copia" row.
@injectable
class GetLastBackupSavedAt {
  const GetLastBackupSavedAt(this._repository);

  final BackupStatusRepository _repository;

  FutureResult<DateTime?> call() => _repository.getLastSavedAt();
}
