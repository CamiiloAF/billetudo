import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_offer_repository.dart';

/// Latches the contextual offer as made (HU-01), so it is never shown again.
///
/// Called when the sheet is presented, not when it is accepted: "Ahora no" is
/// an answer, and re-asking someone who already declined is the nagging this
/// feature is explicitly not allowed to do.
@injectable
class MarkNotificationCaptureOffered {
  const MarkNotificationCaptureOffered(this._repository);

  final CaptureOfferRepository _repository;

  FutureResult<Unit> call() => _repository.markOffered();
}
