import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../tutorials/domain/entities/tutorial_key.dart';
import '../../../tutorials/presentation/widgets/tutorial_auto_show.dart';
import '../../domain/usecases/register_manual_movement_attempt.dart';
import 'start_voice_capture_flow.dart';

/// What the caller should do after the user pressed `+` to add a movement.
enum ManualMovementAddAction {
  /// Nothing else to do: the tutorial's CTA already started a dictation.
  handled,

  /// Open the movement form as the user originally asked. This is also the
  /// answer for "Hacerlo manual", for a skipped gate, and for attempts
  /// before the third.
  openForm,
}

/// Counts one manual `+` attempt and, on the third, offers the voice-gesture
/// tutorial before the form opens (`17-captura-voz.md` HU-02).
///
/// Offered from the `+` of both Inicio and Movimientos, and the counter is
/// shared: it is the same habit being taught. The tutorial appears **instead
/// of** the form, and the user chooses:
/// - "Probar ahora" performs the gesture for them (dictation flow), and the
///   caller does nothing else;
/// - "Hacerlo manual" (the sheet's secondary label for this tutorial) opens
///   the form they were after.
///
/// Returns [ManualMovementAddAction.openForm] when nothing was shown — before
/// the third attempt, when the tutorial was already seen/help is off, or when
/// the ticket-out point was storage failure. A missed tutorial never blocks
/// adding a movement: the long-press hint stays on the FAB either way.
///
/// [startDictation] exists for tests: they assert the third attempt calls it
/// (rather than mounting the real voice sheet and its whole DI graph).
Future<ManualMovementAddAction> offerVoiceGestureTutorialOnManualAdd(
  BuildContext context, {
  Future<void> Function(BuildContext context)? startDictation,
}) async {
  if (!getIt.isRegistered<RegisterManualMovementAttempt>()) {
    // Widget tests build these pages without `configureDependencies()`; the
    // button must keep working exactly as before rather than crash on an
    // unrelated, decorative side-feature (same rule as `maybeShowTutorial`).
    return ManualMovementAddAction.openForm;
  }

  final due = (await getIt<RegisterManualMovementAttempt>()()).fold(
    (_) => false,
    (value) => value,
  );
  if (!due || !context.mounted) {
    return ManualMovementAddAction.openForm;
  }

  var startedDictation = false;
  final outcome = await maybeShowTutorial(
    context,
    TutorialKey.voiceCaptureGesture,
    onCta: (context) async {
      startedDictation = true;
      await (startDictation ?? startVoiceCaptureFlow)(context);
    },
  );
  if (outcome != TutorialShowOutcome.shown || !startedDictation) {
    return ManualMovementAddAction.openForm;
  }
  return ManualMovementAddAction.handled;
}
