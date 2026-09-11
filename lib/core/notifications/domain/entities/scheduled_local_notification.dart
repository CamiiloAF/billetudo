import 'package:equatable/equatable.dart';

import 'app_notification_channel.dart';

/// A single local notification to be delivered at [fireAt] (device-local
/// wall-clock time).
///
/// Pure domain: it carries no plugin type. [id] is a stable integer derived
/// from the owning entity (see `NotificationId`), never a random one — the
/// scheduler reconciles by id, so the same reminder must always resolve to
/// the same number or rescheduling would pile duplicates up.
class ScheduledLocalNotification extends Equatable {
  const ScheduledLocalNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.fireAt,
    this.payload,
  });

  final int id;
  final AppNotificationChannel channel;
  final String title;
  final String body;

  /// Local wall-clock instant. Interpreted in the device's current timezone
  /// by the scheduler, not converted to UTC — a reminder set for "9:00" must
  /// stay at 9:00 after the user flies across a timezone.
  final DateTime fireAt;

  /// Opaque routing payload handed back when the user taps the notification
  /// (e.g. the scheduled payment id). Not parsed by the scheduler.
  final String? payload;

  @override
  List<Object?> get props => [id, channel, title, body, fireAt, payload];
}
