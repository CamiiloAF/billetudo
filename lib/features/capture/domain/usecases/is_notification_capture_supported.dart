import 'package:injectable/injectable.dart';

import '../repositories/notification_capture_repository.dart';

/// Whether this platform can read notifications at all (Android only).
///
/// Every entry point of the feature is gated on this before anything else:
/// on iOS the feature must not appear, not even disabled, because no version
/// of it can ever exist there.
@injectable
class IsNotificationCaptureSupported {
  const IsNotificationCaptureSupported(this._repository);

  final NotificationCaptureRepository _repository;

  bool call() => _repository.isSupported;
}
