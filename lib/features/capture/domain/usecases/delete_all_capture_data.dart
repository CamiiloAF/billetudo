import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_learning_repository.dart';
import '../repositories/pending_capture_repository.dart';

/// "Borrar todas las capturas y lo aprendido" (HU-08): leaves the feature
/// exactly as freshly installed.
///
/// Deliberate boundaries, all three of them:
///  - it deletes captures **physically**, whatever their status, and every
///    learned merchant association;
///  - it does **not** touch transactions already confirmed — those stopped
///    being capture data the moment the user registered them, and erasing
///    them would silently unbalance their accounts;
///  - it does **not** revoke the system permission nor turn the issuers off.
///    Deleting what was captured and deciding to stop capturing are two
///    different decisions, and the user can take either one on its own
///    (HU-09 owns the switch).
@injectable
class DeleteAllCaptureData {
  const DeleteAllCaptureData(this._captures, this._learning);

  final PendingCaptureRepository _captures;
  final CaptureLearningRepository _learning;

  FutureResult<Unit> call() async {
    final capturesResult = await _captures.deleteAllCaptures();
    if (capturesResult case Left(value: final failure)) {
      return Left(failure);
    }
    return _learning.forgetAllLearning();
  }
}
