import 'package:equatable/equatable.dart';

import 'capture_diagnostics.dart';

/// The answer to "can background capture still be trusted right now?" (HU-09).
///
/// It is a snapshot, not a subscription: the caller re-reads it on app start
/// and on every return to foreground, because every input (permission, enabled
/// issuers, the last native capture, the snooze) can change while the app is
/// in the background.
///
/// [degraded] and [showsAttention] are deliberately separate:
///  - [degraded] is the product truth ("capture may have stopped") and stays
///    true even while silenced;
///  - [showsAttention] is "should the card / degraded empty state be drawn
///    right now", which "Ahora no" turns off for 14 days without changing the
///    truth underneath.
class CaptureBackgroundHealth extends Equatable {
  const CaptureBackgroundHealth({
    required this.diagnostics,
    required this.degraded,
    required this.snoozedUntil,
    required this.showsAttention,
  });

  /// The raw device facts the decision was made from, so the sheet can render
  /// its rows without asking the platform again.
  final CaptureDiagnostics diagnostics;

  /// The capture *may* have stopped: the user configured it and nothing (or
  /// nothing recent) arrived. Never true before the user configured it.
  final bool degraded;

  /// Until when "Ahora no" hides the degraded surfaces, or `null` when the
  /// card was never silenced on this device.
  final DateTime? snoozedUntil;

  /// Whether the degraded card / contextual empty state should be shown today.
  /// Always implies [degraded], but not the other way around.
  final bool showsAttention;

  /// The calm, everything-is-fine answer, used when a probe fails or the
  /// preconditions do not hold. Fail closed: a missed card costs the user
  /// nothing, a card that appears by accident is the nagging HU-09 forbids.
  const CaptureBackgroundHealth.calm()
      : diagnostics = const CaptureDiagnostics.empty(),
        degraded = false,
        snoozedUntil = null,
        showsAttention = false;

  @override
  List<Object?> get props =>
      <Object?>[diagnostics, degraded, snoozedUntil, showsAttention];
}
