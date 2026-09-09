import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// Undo of a discard, from the snackbar (HU-05): the capture goes back to
/// `pending` and reappears in the inbox.
///
/// Fails with a `NotFoundFailure` once the row has been purged — the undo
/// window is finite on purpose (privacy), and a silent no-op would let the
/// UI claim it restored something that no longer exists.
@injectable
class RestorePendingCapture {
  const RestorePendingCapture(this._repository);

  final PendingCaptureRepository _repository;

  FutureResult<Unit> call(String captureId) =>
      _repository.restoreCapture(captureId);
}
