import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/manual_movement_attempt_repository.dart';

/// Registers one manual `+` press and answers whether the voice-gesture
/// tutorial is now due (`17-captura-voz.md` HU-02).
///
/// The tutorial teaches a long-press nobody discovers on their own, and it is
/// offered **on the third manual attempt** — late enough that it is clearly
/// about the gesture the user keeps doing, early enough to still be useful.
/// Counting the attempt is part of this call because the "third" rule lives
/// here; presentation only renders the answer.
///
/// Every third attempt is "due" — not only the first one that reaches three:
/// the seen-latch is what actually stops the sheet from returning, and making
/// the counter cycle is what keeps the tutorial recoverable through Ajustes'
/// "reset tutorials" (a counter latched at 3 forever would make it the one
/// tutorial reset cannot bring back). The gate re-check on later cycles is a
/// couple of local reads, and the sheet is never shown twice on its own.
///
/// Answers `false` on any storage failure: a missed tutorial costs nothing
/// (the gesture still works, and Inicio's FAB keeps its long-press hint); a
/// tutorial shown because of a broken counter is worse.
@injectable
class RegisterManualMovementAttempt {
  const RegisterManualMovementAttempt(this._repository);

  /// The product rule: the 3rd attempt offers the tutorial, not the 1st.
  static const int attemptsBeforeOfferingTutorial = 3;

  final ManualMovementAttemptRepository _repository;

  FutureResult<bool> call() async {
    final attempts = await _repository.registerAttempt();
    return attempts.map(
      (count) => count % attemptsBeforeOfferingTutorial == 0,
    );
  }
}
