import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Sends the user to the system's notification-access screen (HU-01). Only
/// ever called AFTER the app's own explainer, never as the first thing the
/// user sees: the system dialog warns, in those words, that the app will be
/// able to read every notification.
@injectable
class OpenNotificationAccessSettings {
  const OpenNotificationAccessSettings(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<Unit> call() => _repository.openPermissionSettings();
}
