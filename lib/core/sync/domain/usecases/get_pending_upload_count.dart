import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/sync_status_repository.dart';

/// Reads, once, how many local changes are still queued for upload (HU-06).
///
/// One shot and not a stream on purpose: "Cerrar sesión" shows it as a photo
/// taken when the sheet opens, to warn about what would be lost if the user
/// also wipes this device. A live counter would move the ground under a
/// decision the user is in the middle of making.
@injectable
class GetPendingUploadCount {
  const GetPendingUploadCount(this._repository);

  final SyncStatusRepository _repository;

  FutureResult<int> call() => _repository.pendingUploadCount();
}
