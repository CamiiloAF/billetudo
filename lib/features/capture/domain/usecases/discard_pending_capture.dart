import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// Throws a capture away (HU-05). Creates no transaction and touches no
/// balance — a capture never was money in the first place.
///
/// The row is not deleted here: it moves to `discarded` so the snackbar can
/// undo it (`RestorePendingCapture`), and `PurgeDiscardedCaptures` erases it
/// for good once that window closes.
///
/// `duplicateOfTransactionId` records the transaction the user pointed at
/// when they answered "Es la misma" to a possible duplicate (HU-07). It is
/// the user's answer being written down, never the app deciding on its own.
@injectable
class DiscardPendingCapture {
  const DiscardPendingCapture(this._repository);

  final PendingCaptureRepository _repository;

  FutureResult<Unit> call(
    String captureId, {
    String? duplicateOfTransactionId,
  }) =>
      _repository.discardCapture(
        captureId,
        duplicateOfTransactionId: duplicateOfTransactionId,
      );
}
