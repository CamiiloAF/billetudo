import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Opens the system's battery-optimization exemption screen for this app
/// (HU-09).
///
/// One use case for one action, as everywhere else: the sheet calls this, not
/// the repository. Opening the screen is all the app can do — it cannot grant
/// the exemption — so the caller re-reads the health when the user returns.
/// A channel failure becomes a `Left`, never a crash.
@injectable
class RequestBatteryOptimizationExemption {
  const RequestBatteryOptimizationExemption(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<Unit> call() => _repository.requestIgnoreBatteryOptimizations();
}
