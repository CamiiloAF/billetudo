import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Asks the system whether notification access is granted right now (HU-09).
/// Called on every app start and on every return to foreground — the state is
/// never assumed from a stored flag, because the user can revoke it from
/// Android Settings without the app knowing.
@injectable
class IsNotificationAccessGranted {
  const IsNotificationAccessGranted(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<bool> call() => _repository.isPermissionGranted();
}
