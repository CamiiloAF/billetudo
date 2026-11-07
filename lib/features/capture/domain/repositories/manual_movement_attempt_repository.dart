import '../../../../core/error/result.dart';

/// Counts how many times the user has opened the manual "new movement" form
/// from the `+` button, so the voice-gesture tutorial can be offered on the
/// third attempt instead of on first visit (`17-captura-voz.md` HU-02).
///
/// Device-local on purpose, like the tutorial's own seen-latch
/// (`TutorialViews`) and the issuer switches: the gesture is about *this*
/// phone, and a counter that synced would show the tutorial at a different
/// moment on each device — or spend the one chance on a fresh install
/// elsewhere.
abstract class ManualMovementAttemptRepository {
  /// Increments the persisted counter and returns the new total.
  ///
  /// Why a counter and not a boolean: "third time" is the product rule, and
  /// keeping the raw count means changing the threshold later is a use-case
  /// change, not a migration.
  FutureResult<int> registerAttempt();
}
