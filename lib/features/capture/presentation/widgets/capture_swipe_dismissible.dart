import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import 'capture_swipe_action.dart';

/// Swipe-to-discard for a pending capture card in the Avisos centre.
///
/// The approved design (`IMs3M` / `bkNc1`) keeps the card untouched in its
/// resting state — no extra glyph, no competing affordance — and reveals a
/// `$expense` action when the user drags it towards the start edge. Only that
/// direction is enabled: the card's other job is opening the pre-filled form,
/// and two opposite gestures on the same target would be a coin toss.
///
/// **Discard is not removal.** `onDiscard` runs the existing
/// `NoticesCubit.discard` flow (`status = discarded`, undoable from the page's
/// snackbar); the inbox removes the row when the stream emits the new list.
/// That is why `confirmDismiss` always answers `false`: the cubit owns when the
/// row leaves the visible list, not this widget, and answering `true` would
/// trip "a dismissed Dismissible is still in the tree" if the write failed or
/// the emission arrived late.
///
/// The gesture is invisible, so the card also exposes a custom accessibility
/// action with the same outcome for screen-reader users.
class CaptureSwipeDismissible extends StatelessWidget {
  const CaptureSwipeDismissible({
    required this.captureId,
    required this.onDiscard,
    required this.child,
    super.key,
  });

  /// Identity of the capture, used only for the [Dismissible] key so the
  /// swipe state follows the row when the list reorders.
  final String captureId;

  final Future<void> Function() onDiscard;

  final Widget child;

  /// Share of the card width the user must cross before the swipe counts.
  static const double discardThreshold = 0.35;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.captureDiscardAction): onDiscard,
      },
      child: Dismissible(
        key: ValueKey<String>('capture-swipe-$captureId'),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: discardThreshold,
        },
        background: const Align(
          alignment: Alignment.centerRight,
          child: CaptureSwipeAction(),
        ),
        confirmDismiss: (direction) async {
          await onDiscard();
          return false;
        },
        child: child,
      ),
    );
  }
}
