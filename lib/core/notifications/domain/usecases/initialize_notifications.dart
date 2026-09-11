import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/notification_scheduler.dart';

/// Prepares the local notification system on app start: timezone database,
/// device timezone and Android channels.
///
/// Does NOT ask for permission — that is
/// `EnsureNotificationPermission`, and it belongs to the moment the user
/// configures their first reminder, not to startup.
@injectable
class InitializeNotifications {
  const InitializeNotifications(this._scheduler);

  final NotificationScheduler _scheduler;

  FutureResult<Unit> call() => _scheduler.initialize();
}
