import 'package:equatable/equatable.dart';

import '../../domain/entities/tutorial_content.dart';

/// Outcome of `TutorialGateCubit.evaluate`.
enum TutorialGateStatus {
  /// No evaluation has run yet.
  idle,

  /// The sheet should be shown for [TutorialGateState.content].
  shouldShow,

  /// Nothing should be shown: already seen, the help preference is off,
  /// the account gate took precedence, or another tutorial already claimed
  /// this navigation (see [TutorialGateState.skipReason]).
  skipped,
}

/// Why [TutorialGateStatus.skipped] happened — only meaningful in that
/// state, kept mainly so tests can assert *which* rule fired.
enum TutorialSkipReason {
  alreadySeen,
  helpDisabled,
  blockedByAccountGate,
  chainedInSameNavigation,
}

class TutorialGateState extends Equatable {
  const TutorialGateState({
    this.status = TutorialGateStatus.idle,
    this.content,
    this.skipReason,
  });

  final TutorialGateStatus status;

  /// Set only when [status] is [TutorialGateStatus.shouldShow].
  final TutorialContent? content;

  /// Set only when [status] is [TutorialGateStatus.skipped].
  final TutorialSkipReason? skipReason;

  @override
  List<Object?> get props => [status, content, skipReason];
}
