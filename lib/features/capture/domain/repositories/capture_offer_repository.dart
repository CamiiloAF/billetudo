import '../../../../core/error/result.dart';

/// Remembers whether the contextual offer of the notification permission has
/// already been made (HU-01).
///
/// The offer appears **once**, right after the user saves their first manual
/// expense, and never again: someone who said "Ahora no" has answered, and
/// asking a second time turns an offer into nagging. Ajustes stays as the
/// permanent way in (HU-09), which is what makes the one-shot acceptable.
abstract class CaptureOfferRepository {
  /// Whether the offer has already been shown on this device.
  FutureResult<bool> hasBeenOffered();

  /// Latches the offer as made. Called when the sheet is shown, not when it
  /// is accepted: the point is that the user saw it, whatever they answered.
  FutureResult<Unit> markOffered();
}
