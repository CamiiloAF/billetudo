import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/notifications/domain/entities/app_notification_channel.dart';
import '../../../../core/notifications/domain/entities/notification_id.dart';
import '../../../../core/notifications/domain/entities/notification_kind.dart';
import '../../../../core/notifications/domain/entities/scheduled_local_notification.dart';
import '../../../../core/notifications/domain/repositories/notification_messages.dart';
import '../../../../core/notifications/domain/repositories/notification_preferences.dart';
import '../../../../core/notifications/domain/repositories/notification_scheduler.dart';
import '../../../../core/utils/money_formatter.dart';
import '../entities/scheduled_payment_reminder.dart';
import '../entities/scheduled_payment_summary.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-08: makes the set of pending reminder notifications match reality,
/// exactly once per call.
///
/// **Reconciliation, not deltas.** Every lifecycle event — creating a
/// template, editing its reminder, confirming/skipping an occurrence (which
/// advances `nextDate`), snoozing one, deleting the template, it passing its
/// `endDate`, the user turning reminders off in Ajustes, an Android reboot
/// wiping the alarms — funnels into this single "what should be pending right
/// now?" computation. A per-event delta would have to get every one of those
/// paths right; this gets them right by construction, and it is idempotent,
/// so calling it twice costs nothing.
///
/// The failure this exists to prevent is an orphan reminder: a notification
/// firing for a payment that was deleted. That is the exact behaviour that
/// teaches people to switch notifications off, so the reconciler cancels
/// anything in the reminders id block that no longer has a live template
/// behind it — including ids it did not create itself.
@injectable
class SyncScheduledPaymentReminders {
  const SyncScheduledPaymentReminders(
    this._repository,
    this._scheduler,
    this._preferences,
    this._messages,
  );

  final ScheduledPaymentRepository _repository;
  final NotificationScheduler _scheduler;
  final NotificationPreferences _preferences;
  final NotificationMessages _messages;

  static const MoneyFormatter _money = MoneyFormatter();

  FutureResult<Unit> call() async {
    final enabled = await _preferences.isEnabled(
      NotificationKind.paymentReminders,
    );

    final templates = await _repository.watchActiveScheduledPayments().first;
    if (templates case Left(value: final failure)) {
      return Left(failure);
    }

    final desired = enabled
        ? _desiredNotifications(
            templates.getOrElse((_) => const <ScheduledPaymentSummary>[]),
          )
        : const <int, ScheduledLocalNotification>{};

    final pending = await _scheduler.pendingIds();
    if (pending case Left(value: final failure)) {
      return Left(failure);
    }

    // Cancel first: an id that stays in `desired` is rescheduled below with
    // its new date, and cancelling then rescheduling is how the OS replaces
    // one anyway.
    for (final id in pending.getOrElse((_) => const <int>[])) {
      if (!NotificationId.belongsTo(id, AppNotificationChannel.reminders)) {
        continue;
      }
      if (desired.containsKey(id)) {
        continue;
      }
      final cancelled = await _scheduler.cancel(id);
      if (cancelled case Left(value: final failure)) {
        return Left(failure);
      }
    }

    for (final notification in desired.values) {
      final scheduled = await _scheduler.schedule(notification);
      if (scheduled case Left(value: final failure)) {
        return Left(failure);
      }
    }

    return const Right(unit);
  }

  Map<int, ScheduledLocalNotification> _desiredNotifications(
    List<ScheduledPaymentSummary> templates,
  ) {
    final now = clock.now();
    final desired = <int, ScheduledLocalNotification>{};

    for (final summary in templates) {
      final template = summary.scheduledPayment;
      final reminder = template.reminder;
      if (reminder == null) {
        continue;
      }

      // `nextPaymentDate`, not the raw cursor: a snoozed occurrence moved the
      // real due date, and reminding for the old one would be wrong twice
      // (too early, and for a date that no longer exists).
      final fireAt = reminderInstant(
        dueDate: summary.nextPaymentDate,
        leadDays: reminder.leadDays,
      );
      if (!fireAt.isAfter(now)) {
        // The lead window already elapsed. Nothing to schedule for this
        // cycle; the next `nextDate` advance will schedule the following one.
        continue;
      }

      final id = NotificationId.forKey(
        template.id,
        AppNotificationChannel.reminders,
      );
      desired[id] = ScheduledLocalNotification(
        id: id,
        channel: AppNotificationChannel.reminders,
        title: _messages.scheduledPaymentReminderTitle(
          template.note ?? _messages.scheduledPaymentUntitled,
        ),
        body: _messages.scheduledPaymentReminderBody(
          leadDays: reminder.leadDays,
          formattedAmount: _money.formatSymbol(
            template.amountMinor,
            currencyCode: template.currency,
          ),
          accountName: summary.accountName,
        ),
        fireAt: fireAt,
        payload: template.id,
      );
    }

    return desired;
  }

  /// The local wall-clock instant a reminder for [dueDate] with [leadDays] of
  /// notice fires at. Exposed (and static) so the arithmetic is unit-testable
  /// without a repository or a scheduler in the loop.
  ///
  /// Rebuilt from year/month/day rather than subtracted as a `Duration`, so a
  /// DST transition inside the lead window cannot shift the hour.
  static DateTime reminderInstant({
    required DateTime dueDate,
    required int leadDays,
  }) =>
      DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - leadDays,
        ScheduledPaymentReminder.fireHour,
      );
}
