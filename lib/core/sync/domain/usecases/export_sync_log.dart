import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_log_repository.dart';

/// Renders the sync log as plain text so the user can share it as evidence.
@injectable
class ExportSyncLog {
  const ExportSyncLog(this._repository);

  final SyncLogRepository _repository;

  FutureResult<String> call() => _repository.exportAsText();
}
