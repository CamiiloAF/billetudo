import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// Batch discard for inbox hygiene (HU-10): everything posted strictly before
/// [DiscardCapturesBefore.call]'s cut-off goes to `discarded` in one action.
///
/// There is no batch confirm, and there will not be one: confirming N
/// captures at once is N blind confirmations, the same non-negotiable rule as
/// in pagos programados. Discarding in batch is safe in a way confirming is
/// not — it creates nothing, and every id it touched is returned so the
/// snackbar can undo exactly those.
@injectable
class DiscardCapturesBefore {
  const DiscardCapturesBefore(this._repository);

  final PendingCaptureRepository _repository;

  FutureResult<List<String>> call(DateTime postedBefore) =>
      _repository.discardCapturesBefore(postedBefore);
}
