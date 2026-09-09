import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// How many captures are waiting for a decision, for the Home bell badge
/// (HU-04).
///
/// Counts the exact same set `WatchPendingCaptures` shows, so the badge and
/// the screen it opens can never disagree. Capping ("9+") and hiding the
/// badge on zero belong to the widget, not here: this only ever returns the
/// true count, and the copy around it never reproaches the user for it.
@injectable
class WatchPendingCaptureCount {
  const WatchPendingCaptureCount(this._repository);

  final PendingCaptureRepository _repository;

  Stream<Result<int>> call() => _repository.watchPendingCaptureCount();
}
