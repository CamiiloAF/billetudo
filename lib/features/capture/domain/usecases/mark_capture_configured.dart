import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_background_preferences_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Latches the moment the user completed background capture, exactly once
/// (HU-09).
///
/// This is the start of the clock for the three-day "configured and never
/// captured" grace period. It is written **only** when all three preconditions
/// hold — permission granted, at least one issuer enabled, and no date stored
/// yet — and it never overwrites an existing date: moving the mark forward on
/// every settings visit would postpone the alarm forever.
///
/// Called by the presentation layer when the configuration flow completes. A
/// failure to read any precondition is "nothing to mark", not an error: the
/// next visit re-checks and marks if it can. Only a failed **write** surfaces
/// as a `Left`.
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

    return _preferences.markConfigured(clock.now());
  }
}
