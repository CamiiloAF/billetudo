import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/notification_scheduler.dart';

/// Takes the user to the phone's settings for this app.
///
/// The only way out of a permanently denied notification permission: from
/// that point the OS stops showing the prompt and answers "denied" without
/// asking, so the app can only point at the door, never open it.
@injectable
class OpenNotificationSystemSettings {
  const OpenNotificationSystemSettings(this._scheduler);

  final NotificationScheduler _scheduler;

  FutureResult<Unit> call() => _scheduler.openSystemSettings();
}
