import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Enforces "never chain two tutorials in the same navigation"
/// (`docs/requirements/16-minitutoriales.md` HU-02): if a HU-01 screen
/// tutorial and a HU-02 sub-flow one would both qualify for the same screen
/// entry, only one shows and the other waits for the next visit.
///
/// A single [claim] within [window] of the previous one wins; every later
/// one loses. `window` approximates "the same navigation" as "close enough in
/// wall-clock time to be the same user gesture landing on a new screen" —
/// every real trigger site calls `TutorialGateCubit.evaluate` from a
/// post-frame callback right after its widget mounts, so two tutorials
/// genuinely competing for the same entry always land within a handful of
/// milliseconds of each other, while two unrelated visits minutes (or days)
/// apart never collide.
///
/// App-wide singleton on purpose: the "same navigation" rule spans whichever
/// screen or sub-flow trigger fires first, not a single cubit instance's
/// lifetime (each trigger site owns its own short-lived `TutorialGateCubit`).
@lazySingleton
class TutorialNavigationGuard {
  static const Duration window = Duration(milliseconds: 700);

  DateTime? _lastClaimAt;

  /// Attempts to claim the "show a tutorial now" slot. Returns `true` (and
  /// records the claim) when no other tutorial claimed it within [window];
  /// returns `false` otherwise, meaning the caller must not show its sheet.
  bool claim({DateTime? now}) {
    final resolvedNow = now ?? clock.now();
    final lastClaimAt = _lastClaimAt;
    if (lastClaimAt != null && resolvedNow.difference(lastClaimAt) < window) {
      return false;
    }
    _lastClaimAt = resolvedNow;
    return true;
  }

  /// Test-only: clears the guard so each test starts from a clean slate.
  @visibleForTesting
  void reset() => _lastClaimAt = null;
}
