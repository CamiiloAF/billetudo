import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/tutorial_content.dart';
import '../../domain/usecases/has_seen_tutorial.dart';
import '../../domain/usecases/watch_help_enabled.dart';
import '../utils/tutorial_navigation_guard.dart';
import 'tutorial_gate_state.dart';

/// Decides whether a minitutorial sheet should auto-show on a given screen
/// or sub-flow entry (`docs/requirements/fase-1/16-minitutoriales.md`).
///
/// Orchestrates only use cases ([HasSeenTutorial], [WatchHelpEnabled]) plus
/// [TutorialNavigationGuard] — never a repository or DAO directly. One
/// short-lived instance per trigger site (`@injectable`, not a singleton):
/// the "same navigation" rule that spans *multiple* trigger sites lives in
/// the shared, singleton [TutorialNavigationGuard] instead.
@injectable
class TutorialGateCubit extends Cubit<TutorialGateState> {
  TutorialGateCubit(
    this._hasSeenTutorial,
    this._watchHelpEnabled,
    this._navigationGuard,
  ) : super(const TutorialGateState());

  final HasSeenTutorial _hasSeenTutorial;
  final WatchHelpEnabled _watchHelpEnabled;
  final TutorialNavigationGuard _navigationGuard;

  /// Evaluates whether [content] should auto-show right now.
  ///
  /// [accountGateShown] is `true` when the caller already had to (and did)
  /// show the account gate bridge for this same entry
  /// (`docs/requirements/fase-1/15-gate-cuenta.md`) — that gate has absolute
  /// precedence (criterion 7): the tutorial stays pending for the next valid
  /// visit, and — crucially — [TutorialNavigationGuard.claim] is never
  /// called in that branch, so it does not consume the "one tutorial per
  /// navigation" slot either.
  ///
  /// Never called for "Ver ayuda"/reopen — that path renders [content]
  /// directly without going through the gate (HU-03: reopening never alters
  /// anything, including this evaluation).
  Future<bool> evaluate({
    required TutorialContent content,
    bool accountGateShown = false,
  }) async {
    if (accountGateShown) {
      emit(
        const TutorialGateState(
          status: TutorialGateStatus.skipped,
          skipReason: TutorialSkipReason.blockedByAccountGate,
        ),
      );
      return false;
    }

    final helpEnabledResult = await _watchHelpEnabled().first;
    final helpEnabled = helpEnabledResult.fold((_) => true, (v) => v);
    if (!helpEnabled) {
      emit(
        const TutorialGateState(
          status: TutorialGateStatus.skipped,
          skipReason: TutorialSkipReason.helpDisabled,
        ),
      );
      return false;
    }

    final seenResult = await _hasSeenTutorial(content.key);
    final seen = seenResult.fold((_) => true, (v) => v);
    if (seen) {
      emit(
        const TutorialGateState(
          status: TutorialGateStatus.skipped,
          skipReason: TutorialSkipReason.alreadySeen,
        ),
      );
      return false;
    }

    if (!_navigationGuard.claim()) {
      emit(
        const TutorialGateState(
          status: TutorialGateStatus.skipped,
          skipReason: TutorialSkipReason.chainedInSameNavigation,
        ),
      );
      return false;
    }

    emit(
      TutorialGateState(status: TutorialGateStatus.shouldShow, content: content),
    );
    return true;
  }
}
