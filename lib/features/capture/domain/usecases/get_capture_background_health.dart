import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/capture_background_health.dart';
import '../entities/capture_diagnostics.dart';
import '../repositories/capture_background_preferences_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Decides whether background capture may have stopped (HU-09).
///
/// **This is the only implementation of the rule.** The card in Avisos, the
/// contextual empty state and the sheet footer all consume this answer; none
/// of them re-implements the dates. That matters because the formula has two
/// different grace periods and a snooze, and three copies of it would drift.
///
/// ```
/// degraded =
///   permissionGranted && enabledCount > 0 && configuredAt != null &&
///   ((lastListenerConnectedAt == null && now - configuredAt >= 5 minutes) ||
///    (lastListenerConnectedAt != null && !listenerConnectedNow &&
///     now - lastListenerConnectedAt >= 6 hours) ||
///    (lastCaptureAt == null && now - configuredAt >= 3 days) ||
///    (lastCaptureAt != null && now - lastCaptureAt >= 7 days))
///
/// showsAttention = degraded && (snoozedUntil == null || now >= snoozedUntil)
/// ```
///
/// The first two clauses are **direct** signals and show the problem in
/// minutes, not days: `lastListenerConnectedAt` is written by the native
/// `NotificationListenerService` in `onListenerConnected` (when MIUI/HyperOS
/// rejects the bind it stays `null` forever) and `listenerConnectedNow` is the
/// live process state of the service. The last two clauses stay as the
/// heuristic fallback for "connected, but the banks sent nothing".
///
/// Why the heuristic asymmetry: someone who just configured capture and has not
/// received anything yet gets three days of patience (banks do not notify every
/// day); someone who *was* receiving and then stopped gets seven, because a new
/// capture always clears the alarm immediately.
///
/// **`configuredAt == null` is not degraded.** Installations that predate this
/// flow never marked a configuration date; alarming them on the next open
/// would say "your capture is broken" without ever having watched it work. The
/// mark is written once by `MarkCaptureConfigured`.
///
/// A probe that cannot be completed answers [CaptureBackgroundHealth.calm]:
/// silently showing nothing is a missed card, showing it on a guess is the
/// nagging the product explicitly forbids.
@injectable
class GetCaptureBackgroundHealth {
  const GetCaptureBackgroundHealth(this._capture, this._preferences);

  /// Grace period since configuration for a device that never captured.
  static const Duration noCaptureGracePeriod = Duration(days: 3);

  /// Grace period since the last capture for a device that used to capture.
  static const Duration staleCaptureGracePeriod = Duration(days: 7);

  /// How long a freshly configured device gets before "the listener never
  /// connected" becomes an alarm. Minutes, not days: the bind happens (or is
  /// rejected) right after the permission is granted, so this is the direct
  /// signal and the user must not be left three days without a word.
  static const Duration neverConnectedGracePeriod = Duration(minutes: 5);

  /// How long a listener that *was* connected may stay disconnected before the
  /// capture is considered stopped. The service rebinds by itself and the
  /// system reconnects it on unlock, so a short gap is normal.
  static const Duration staleConnectionWindow = Duration(hours: 6);

  final NotificationCaptureRepository _capture;
  final CaptureBackgroundPreferencesRepository _preferences;

  FutureResult<CaptureBackgroundHealth> call() async {
    // Cheap preconditions first: the two existing states (permission and
    // issuers) take precedence, so nothing is read from the phone or the
    // preferences when one of them is missing.
    final Result<bool> granted = await _capture.isPermissionGranted();
    final bool hasPermission = granted.getOrElse((_) => false);
    if (!hasPermission) {
      return const Right(CaptureBackgroundHealth.calm());
    }

    final Result<Set<String>> enabled = await _capture.getEnabledIssuers();
    final Set<String> issuers = enabled.getOrElse((_) => const <String>{});
    if (issuers.isEmpty) {
      return const Right(CaptureBackgroundHealth.calm());
    }

    final Result<DateTime?> configured = await _preferences.configuredAt();
    // An unreadable date is treated as "not configured": no alarm.
    final DateTime? configuredAt = configured.getOrElse((_) => null);
    if (configuredAt == null) {
      return const Right(CaptureBackgroundHealth.calm());
    }

    // Only now does the device state matter; asking the platform before this
    // point would be a channel call whose answer could never be shown.
    final Result<CaptureDiagnostics> diagnostics =
        await _capture.getDiagnostics();
    if (diagnostics case Left()) {
      return const Right(CaptureBackgroundHealth.calm());
    }
    final CaptureDiagnostics device =
        diagnostics.getOrElse((_) => const CaptureDiagnostics.empty());

    final Result<DateTime?> snoozed = await _preferences.snoozedUntil();
    if (snoozed case Left()) {
      // Cannot verify whether the user silenced the card: fail closed.
      return const Right(CaptureBackgroundHealth.calm());
    }
    final DateTime? snoozedUntil = snoozed.getOrElse((_) => null);

    final DateTime now = clock.now();
    final DateTime? lastCaptureAt = device.lastCaptureAt;
    final bool degraded = _isDegraded(
      now: now,
      configuredAt: configuredAt,
      lastCaptureAt: lastCaptureAt,
      lastListenerConnectedAt: device.lastListenerConnectedAt,
      listenerConnectedNow: device.listenerConnectedNow,
    );
    final bool showsAttention =
        degraded && (snoozedUntil == null || !now.isBefore(snoozedUntil));

    return Right(
      CaptureBackgroundHealth(
        diagnostics: device,
        degraded: degraded,
        snoozedUntil: snoozedUntil,
        showsAttention: showsAttention,
      ),
    );
  }

  bool _isDegraded({
    required DateTime now,
    required DateTime configuredAt,
    required DateTime? lastCaptureAt,
    required DateTime? lastListenerConnectedAt,
    required bool listenerConnectedNow,
  }) {
    // Direct signals first: they are true facts about the listener itself,
    // independent of whether any bank happened to notify.
    final bool neverConnected = lastListenerConnectedAt == null &&
        now.difference(configuredAt) >= neverConnectedGracePeriod;
    final bool disconnected = lastListenerConnectedAt != null &&
        !listenerConnectedNow &&
        now.difference(lastListenerConnectedAt) >= staleConnectionWindow;
    if (neverConnected || disconnected) {
      return true;
    }
    // Heuristic fallback: the listener looks fine, but nothing arrived.
    if (lastCaptureAt == null) {
      return now.difference(configuredAt) >= noCaptureGracePeriod;
    }
    return now.difference(lastCaptureAt) >= staleCaptureGracePeriod;
  }
}
