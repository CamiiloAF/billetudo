import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_offer_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Decides whether to make the contextual offer of the notification permission
/// after a manual expense has just been saved (HU-01).
///
/// Three conditions, all required, checked in the cheapest order:
///
///  1. the platform supports it (Android),
///  2. the offer has never been made on this device, and
///  3. the permission is **not** already granted — asked to the system, never
///     read from a flag, so someone who granted it from Ajustes is not
///     offered something they already have.
///
/// Answers `false` on any failure. A missed offer costs the user nothing (the
/// permanent entry in Ajustes is always there); an offer shown by accident
/// spends the single chance this feature gets.
@injectable
class ShouldOfferNotificationCapture {
  const ShouldOfferNotificationCapture(this._capture, this._offer);

  final NotificationCaptureRepository _capture;
  final CaptureOfferRepository _offer;

  Future<bool> call() async {
    if (!_capture.isSupported) {
      return false;
    }
    final Result<bool> offered = await _offer.hasBeenOffered();
    if (offered case Right(value: final bool wasOffered) when !wasOffered) {
      final Result<bool> granted = await _capture.isPermissionGranted();
      return switch (granted) {
        Right(value: final bool value) => !value,
        // Could not ask the system, so offering would be a guess. Ajustes
        // stays available either way.
        Left() => false,
      };
    }
    return false;
  }
}
