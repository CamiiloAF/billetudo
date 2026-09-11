import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/notifications/domain/entities/app_notification_channel.dart';
import '../../../../core/notifications/domain/entities/notification_id.dart';
import '../../../../core/notifications/domain/repositories/notification_scheduler.dart';

/// Cancels the pending reminder of a single template, right now.
///
/// `SyncScheduledPaymentReminders` would drop it too (a deleted template is
/// no longer active, so it is not in the desired set), but deletion gets its
/// own direct call for one reason: it is the case where an orphan
/// notification is worst — a reminder ringing for a payment the user just
/// deleted — so it must not depend on the reconciler managing to read the
/// database afterwards.
@injectable
class CancelScheduledPaymentReminder {
  const CancelScheduledPaymentReminder(this._scheduler);

  final NotificationScheduler _scheduler;

  FutureResult<Unit> call(String scheduledPaymentId) => _scheduler.cancel(
        NotificationId.forKey(
          scheduledPaymentId,
          AppNotificationChannel.reminders,
        ),
      );
}
