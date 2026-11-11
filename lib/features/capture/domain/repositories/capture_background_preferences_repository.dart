import '../../../../core/error/result.dart';

/// Remembers the two per-device dates behind the degraded state (HU-09).
///
/// Local and not a synced Drift column, for the same reason the issuer
/// switches are: the notification-access permission is granted per device, so
/// "configured on this phone" and "silenced on this phone" are facts about
/// **this phone**. Syncing them would silence the card on a device that never
/// configured anything, or show it on one that already dismissed it.
abstract class CaptureBackgroundPreferencesRepository {
  /// When the user first completed permission + at least one issuer, or `null`
  /// when that never happened on this device.
  ///
  /// `null` is load-bearing: a pre-existing installation that never went
  /// through the new flow must not receive an alarm on the next open. The mark
  /// is written by `MarkCaptureConfigured`, once.
  FutureResult<DateTime?> configuredAt();

  /// Until when "Ahora no" hides the degraded surfaces, or `null` when the card
  /// was never silenced.
  ///
  /// Named `snoozedUntil` and not `snoozeUntil` because that name belongs to
  /// the write operation below, and Dart does not allow a getter and a method
  /// to share one.
  FutureResult<DateTime?> snoozedUntil();

  /// Latches [configuredAt] **once**. Must never overwrite an existing mark: a
  /// later settings change is not a new configuration, and shifting the date
  /// forward would postpone the alarm forever.
  FutureResult<Unit> markConfigured(DateTime at);

  /// Stores the new [until] date, replacing any previous snooze. It must never
  /// touch captures, issuers or the permission: "Ahora no" only silences the
  /// card.
  FutureResult<Unit> snoozeUntil(DateTime until);
}
