import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Opens the manufacturer's autostart screen, falling back to the app's
/// details page (HU-09).
///
/// Only reachable on brands that expose a destination; the sheet hides the row
/// elsewhere. Like the battery action, it only opens a screen, so the caller
/// re-reads the health afterwards instead of assuming success. A channel
/// failure becomes a `Left`, never a crash.
@injectable
class OpenCaptureAutostartSettings {
  const OpenCaptureAutostartSettings(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<Unit> call() => _repository.openAutostartSettings();
}
