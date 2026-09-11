import 'app_notification_channel.dart';

/// The kinds of notice the user can turn on or off individually in Ajustes.
///
/// Finer-grained than [AppNotificationChannel] on purpose: the OS channel is
/// what Android exposes in system settings, this is what billetudo exposes
/// in its own. Three of these ride on the same `milestones`/`reminders`
/// channel, and a user who likes due-date reminders but not "hito de meta"
/// must be able to say so inside the app instead of silencing the channel.
///
/// Notification fatigue is the classic failure mode of this feature: the
/// first irrelevant notice trains the person to ignore every one after it.
enum NotificationKind {
  /// Due-date reminders configured per scheduled payment (HU-08). Note the
  /// per-template preference still rules: this is the global off switch, not
  /// an opt-in.
  paymentReminders(AppNotificationChannel.reminders),

  /// "Netflix se cobra en 3 días" — a projected upcoming charge.
  upcomingCharges(AppNotificationChannel.reminders),

  /// A manual-mode occurrence waiting to be confirmed.
  pendingConfirmations(AppNotificationChannel.reminders),

  /// "Alcanzaste tu meta de viaje" — positive reinforcement.
  goalMilestones(AppNotificationChannel.milestones);

  const NotificationKind(this.channel);

  /// The OS channel a notice of this kind is delivered on.
  final AppNotificationChannel channel;
}
