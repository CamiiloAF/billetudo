import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/capture_diagnostics.dart';
import '../repositories/capture_background_preferences_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Latches the moment the user completed background capture, exactly once
/// (HU-09).
///
/// This is the start of the clock for the "configured and never captured"
/// grace period. It is written **only** when all three preconditions hold —
/// permission granted, at least one issuer enabled, and no date stored yet —
/// and it never overwrites an existing date: moving the mark forward on every
/// settings visit would postpone the alarm forever.
///
/// **Migration (2026-11-11): the mark is backfilled from the last capture, not
/// from "now".** The first HU-09 release only wrote it from the issuer catalog
/// screen, so a device configured with an earlier build kept `configuredAt`
/// `null` and the degraded rule answered "never configured" forever — the app
/// stayed silent while capture was dead, which is the exact report that
/// reopened this. When the native listener already produced a capture, that
/// timestamp is proof the device was configured at least since then, so an
/// upgraded installation gets its real clock back instead of a fresh grace
/// period.
///
/// Deliberately **not** anchored on `lastListenerConnectedAt`: the heartbeat is
/// written when the system binds the listener, which can happen days before the
/// user switches an issuer on. Using it as the configuration date would turn a
/// just-configured device into an immediate false alarm, and HU-09 forbids
/// nagging on a guess. Without a capture there is no proof of configuration, so
/// the clock starts now and the normal grace periods apply.
///
/// A failed read of the diagnostics falls back to "now": the rule can then only
/// get a **later** start, never a false alarm from missing data.
///
/// Called by the presentation layer when the configuration flow completes and
/// on every background-health read, where it is idempotent: an existing mark
/// short-circuits before the expensive checks.
@injectable
class MarkCaptureConfigured {
  const MarkCaptureConfigured(this._capture, this._preferences);

  final NotificationCaptureRepository _capture;
  final CaptureBackgroundPreferencesRepository _preferences;

  FutureResult<Unit> call() async {
    final Result<DateTime?> existing = await _preferences.configuredAt();
    if (existing case Left()) {
      // Writing without being able to check would risk overwriting the
      // original mark.
      return const Right(unit);
    }
    if (existing.getOrElse((_) => null) != null) {
      return const Right(unit);
    }

    final Result<bool> granted = await _capture.isPermissionGranted();
    final bool hasPermission = switch (granted) {
      Right(value: final bool value) => value,
      Left() => false,
    };
    if (!hasPermission) {
      return const Right(unit);
    }

    final Result<Set<String>> enabled = await _capture.getEnabledIssuers();
    final bool hasIssuers = switch (enabled) {
      Right(value: final Set<String> ids) => ids.isNotEmpty,
      Left() => false,
    };
    if (!hasIssuers) {
      return const Right(unit);
    }

    return _preferences.markConfigured(await _anchor());
  }

  /// The instant this device last proved it captured something, or "now" when
  /// nothing proves it. A future value (a skewed device clock) is clamped to
  /// now: a mark in the future would silence the degraded rule for the whole
  /// skew.
  Future<DateTime> _anchor() async {
    final DateTime now = clock.now();
    final Result<CaptureDiagnostics> diagnostics =
        await _capture.getDiagnostics();
    final CaptureDiagnostics device =
        diagnostics.getOrElse((_) => const CaptureDiagnostics.empty());
    final DateTime? lastCaptureAt = device.lastCaptureAt;
    if (lastCaptureAt == null || lastCaptureAt.isAfter(now)) {
      return now;
    }
    return lastCaptureAt;
  }
}
