/// The Android notification channels billetudo declares, one per kind of
/// notice.
///
/// One channel per kind is deliberate: Android exposes channels individually
/// in system settings, so a user who does not want, say, milestone
/// celebrations can silence exactly that without losing the due-date
/// reminders they explicitly configured. A single "billetudo" channel would
/// make that an all-or-nothing choice, which is the fastest way to lose every
/// notification permission this app will ever get.
enum AppNotificationChannel {
  /// Due-date reminders for scheduled payments (HU-08). The only channel the
  /// user opts into explicitly, per template.
  reminders('reminders'),

  /// Low-friction capture nudges (Fase 2). Declared now so the channel id is
  /// stable before anything ships on it; nothing schedules on it yet.
  captures('captures'),

  /// Positive reinforcement: goal milestones reached (Fase 3 insights).
  milestones('milestones');

  const AppNotificationChannel(this.id);

  /// Stable channel id. Never change one of these: Android keys the user's
  /// per-channel settings by id, and a new id silently resets them.
  final String id;
}
