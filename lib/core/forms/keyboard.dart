import 'package:flutter/widgets.dart';

/// Bounded polling step/limit for [dismissSystemKeyboard]'s wait below: 16ms
/// (one frame) per step, up to 20 steps (~320ms) — comfortably above a real
/// device's on-screen-keyboard close animation (Android/iOS both land well
/// under 300ms) without ever hanging a caller if the inset never quite
/// reaches zero for some other reason.
const _keyboardPollStep = Duration(milliseconds: 16);
const _keyboardPollMaxSteps = 20;

/// Drops the system keyboard before a selector sheet/picker opens.
///
/// Unfocusing the primary focus itself (not `FocusScope.of(context)`) removes
/// the field from every enclosing scope's focus history, so the modal route has
/// nothing to restore on close. `FocusScope.of(context).unfocus()` only clears
/// the nearest scope and leaves the field registered in a nested scope, so the
/// route re-focuses it on close and the keyboard springs back up — verified in
/// the deudas form, whose fields sit under a nested scope.
///
/// The focus change is applied on a microtask, so awaiting at least one tick
/// here lets the field lose focus BEFORE the sheet route is pushed; otherwise
/// the route captures the still-focused field. Callers must re-check
/// `context.mounted` before using the context again.
///
/// On a real device (unlike a mocked `flutter test` TextInput channel), the
/// on-screen keyboard's own close *animation* takes a real, non-zero amount
/// of time: `MediaQuery.viewInsets.bottom` does not drop to `0` the instant
/// focus is lost, it eases down over the next couple hundred milliseconds.
/// A caller that opens a non-scrollable, fixed-height sheet (e.g.
/// `DatePickerSheet`) right after this used to race that animation — the
/// sheet's first frame could still land mid-animation, with less height
/// available than the keyboard-free layout assumes, overflowing by however
/// much inset was still left. Waiting here, bounded, for the inset to
/// actually settle closes that race at its source instead of making every
/// caller sheet defensively scrollable.
Future<void> dismissSystemKeyboard(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  for (var step = 0; step < _keyboardPollMaxSteps; step++) {
    if (!context.mounted) {
      return;
    }
    if (MediaQuery.viewInsetsOf(context).bottom <= 0) {
      return;
    }
    await Future<void>.delayed(_keyboardPollStep);
  }
}
