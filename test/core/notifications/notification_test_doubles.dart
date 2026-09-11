import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/notifications/domain/entities/app_notification_channel.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_id.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_kind.dart';
import 'package:billetudo/core/notifications/domain/entities/scheduled_local_notification.dart';
import 'package:billetudo/core/notifications/domain/repositories/notification_messages.dart';
import 'package:billetudo/core/notifications/domain/repositories/notification_preferences.dart';
import 'package:billetudo/core/notifications/domain/repositories/notification_scheduler.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/sync_scheduled_payment_reminders.dart';
import 'package:mocktail/mocktail.dart';

/// An in-memory [NotificationScheduler] that behaves like the real one
/// (schedule replaces by id, cancel removes, pending reports what is armed)
/// without touching a platform channel — so the reminder lifecycle can be
/// asserted end to end.
class FakeNotificationScheduler implements NotificationScheduler {
  final Map<int, ScheduledLocalNotification> scheduled =
      <int, ScheduledLocalNotification>{};
  final List<int> cancelledIds = <int>[];

  bool permissionGranted = true;
  bool permissionRequested = false;
  bool initialized = false;

  /// When true every scheduling call fails, to assert that a notification
  /// failure never takes a business write down with it.
  bool failEverything = false;

  List<int> get scheduledIds => scheduled.keys.toList();

  @override
  FutureResult<Unit> initialize() async {
    initialized = true;
    return const Right(unit);
  }

  @override
  FutureResult<bool> hasPermission() async =>
      failEverything ? const Left(UnexpectedFailure('nope')) : Right(
          permissionGranted,
        );

  @override
  FutureResult<bool> requestPermission() async {
    permissionRequested = true;
    return Right(permissionGranted);
  }

  /// Whether the app was sent to the phone's settings screen.
  bool systemSettingsOpened = false;

  @override
  FutureResult<Unit> openSystemSettings() async {
    systemSettingsOpened = true;
    return const Right(unit);
  }

  @override
  FutureResult<Unit> schedule(ScheduledLocalNotification notification) async {
    if (failEverything) {
      return const Left(UnexpectedFailure('nope'));
    }
    scheduled[notification.id] = notification;
    return const Right(unit);
  }

  @override
  FutureResult<Unit> cancel(int id) async {
    if (failEverything) {
      return const Left(UnexpectedFailure('nope'));
    }
    cancelledIds.add(id);
    scheduled.remove(id);
    return const Right(unit);
  }

  @override
  FutureResult<List<int>> pendingIds() async =>
      failEverything ? const Left(UnexpectedFailure('nope')) : Right(
          scheduled.keys.toList(),
        );

  @override
  FutureResult<Unit> cancelChannel(AppNotificationChannel channel) async {
    for (final id in scheduled.keys.toList()) {
      if (NotificationId.belongsTo(id, channel)) {
        await cancel(id);
      }
    }
    return const Right(unit);
  }
}

/// In-memory preferences, every kind on unless a test says otherwise.
class FakeNotificationPreferences implements NotificationPreferences {
  final Map<NotificationKind, bool> values = <NotificationKind, bool>{};

  @override
  Future<bool> isEnabled(NotificationKind kind) async =>
      values[kind] ?? true;

  @override
  Future<void> setEnabled(
    NotificationKind kind, {
    required bool enabled,
  }) async =>
      values[kind] = enabled;

  @override
  Future<Map<NotificationKind, bool>> readAll() async => <NotificationKind, bool>{
        for (final kind in NotificationKind.values) kind: values[kind] ?? true,
      };
}

/// Deterministic copy, so assertions never depend on the `.arb`.
class FakeNotificationMessages implements NotificationMessages {
  @override
  String channelName(AppNotificationChannel channel) => 'channel:${channel.id}';

  @override
  String channelDescription(AppNotificationChannel channel) =>
      'description:${channel.id}';

  @override
  String scheduledPaymentReminderTitle(String templateName) => templateName;

  @override
  String scheduledPaymentReminderBody({
    required int leadDays,
    required String formattedAmount,
    required String accountName,
  }) =>
      'lead=$leadDays amount=$formattedAmount account=$accountName';

  @override
  String get scheduledPaymentUntitled => 'Pago programado';
}

class MockSyncScheduledPaymentReminders extends Mock
    implements SyncScheduledPaymentReminders {}

/// A [SyncScheduledPaymentReminders] double that succeeds and does nothing —
/// what most existing tests of the scheduled payments use cases need, since
/// they assert the write, not the notification.
MockSyncScheduledPaymentReminders noopSyncReminders() {
  final mock = MockSyncScheduledPaymentReminders();
  when(mock.call).thenAnswer((_) async => const Right(unit));
  return mock;
}
