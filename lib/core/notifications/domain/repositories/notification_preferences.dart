import '../entities/notification_kind.dart';

/// Per-kind on/off preferences for billetudo's own notices, plus the daily
/// frequency cap they all share.
///
/// Device-scoped (not `AppSettings`/PowerSync), same reasoning as
/// `ThemePreferenceDatasource`: which notices this phone shows is a property
/// of this phone, and two devices of the same account should not fight over
/// it.
abstract class NotificationPreferences {
  /// Whether [kind] is enabled. Every kind defaults to ON except where the
  /// implementation documents otherwise — a reminder the user configured
  /// per-template must not need a second opt-in.
  Future<bool> isEnabled(NotificationKind kind);

  Future<void> setEnabled(NotificationKind kind, {required bool enabled});

  /// Current value of every kind, for the Ajustes section.
  Future<Map<NotificationKind, bool>> readAll();
}
