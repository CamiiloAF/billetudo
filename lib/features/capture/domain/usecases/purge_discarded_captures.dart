import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// Erases discarded captures for good once the undo window has passed
/// (HU-10).
///
/// **Physical deletion, not `deletedAt`.** There is no value in keeping the
/// trace of something the user said was not theirs, and there is a privacy
/// cost in keeping it — the row would keep syncing and sitting in backups.
/// `deletedAt` exists for a trash the user can open again; this is the
/// opposite situation.
@injectable
class PurgeDiscardedCaptures {
  const PurgeDiscardedCaptures(this._repository);

  /// How long a discarded capture stays undoable. Comfortably longer than a
  /// snackbar, so a purge triggered right after a discard can never race the
  /// undo the user is still able to tap.
  static const Duration undoWindow = Duration(minutes: 30);

  final PendingCaptureRepository _repository;

  /// Returns how many rows were removed. [now] is injectable for tests.
  FutureResult<int> call({DateTime? now}) => _repository.purgeDiscardedCaptures(
        (now ?? DateTime.now()).subtract(undoWindow),
      );
}
