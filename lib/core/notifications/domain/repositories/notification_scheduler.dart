import '../../../error/result.dart';
import '../entities/app_notification_channel.dart';
import '../entities/scheduled_local_notification.dart';

/// Contract over the device's local notification system. Implemented in
/// `data/` on top of `flutter_local_notifications` + `timezone`.
///
/// Every method is total (returns a [Failure] instead of throwing): a
/// notification that could not be scheduled must never take a save with it.
/// Notifications are a courtesy on top of data the app already holds, so a
/// scheduling error degrades the experience, it does not break a write.
abstract class NotificationScheduler {
  /// Loads the timezone database, resolves the device timezone and registers
  /// the Android channels. Idempotent: safe to call on every start.
  FutureResult<Unit> initialize();

  /// Whether the OS currently allows this app to post notifications. On
  /// Android < 13 this is always true; on Android 13+ it reflects
  /// `POST_NOTIFICATIONS`.
  FutureResult<bool> hasPermission();

  /// Prompts for the notification permission. MUST be called in context (the
  /// moment the user configures their first reminder), never at startup: a
  /// permission prompt with no explanation is the one that gets denied
  /// permanently.
  FutureResult<bool> requestPermission();

  /// Schedules (or replaces, same [ScheduledLocalNotification.id])
  /// [notification]. A [notification] whose `fireAt` is already in the past
  /// is dropped, not fired immediately — a reminder for a date that already
  /// went by is noise.
  FutureResult<Unit> schedule(ScheduledLocalNotification notification);

  /// Cancels a single pending notification. A no-op when nothing is pending
  /// under that id.
  FutureResult<Unit> cancel(int id);

  /// Ids of every notification currently pending delivery. Used to reconcile
  /// (cancel what no longer has a reason to exist) instead of blindly
  /// rescheduling.
  FutureResult<List<int>> pendingIds();

  /// Cancels every pending notification on [channel], leaving other channels
  /// untouched — what happens when the user turns that kind of notice off in
  /// Ajustes.
  FutureResult<Unit> cancelChannel(AppNotificationChannel channel);
}
