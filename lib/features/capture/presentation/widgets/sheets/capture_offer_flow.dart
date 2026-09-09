import 'package:flutter/widgets.dart';

import '../../../domain/usecases/mark_notification_capture_offered.dart';
import '../../../domain/usecases/should_offer_notification_capture.dart';
import 'capture_offer_sheet.dart';

/// The one-shot contextual offer of the notification permission (HU-01).
///
/// Lives here rather than in the router so the eligibility rule and the sheet
/// stay together, and so the router only has to say *when* the moment is: the
/// instant a manual expense was saved.
///
/// It is deliberately **quiet on every failure**. Nothing about this offer is
/// worth interrupting the user over: if the check cannot run, the sheet
/// simply does not appear, and the permanent entry in Ajustes (HU-09) is
/// still the way in. It also opens nothing if the user left the screen in the
/// meantime.
abstract final class CaptureOfferFlow {
  /// Offers the permission if this device is eligible, and latches the offer
  /// as made either way — "Ahora no" is an answer, and asking again would
  /// turn an offer into nagging.
  ///
  /// [onSeeHowItWorks] is invoked only when the user asks for the explainer.
  static Future<void> maybeOffer(
    BuildContext context, {
    required ShouldOfferNotificationCapture shouldOffer,
    required MarkNotificationCaptureOffered markOffered,
    required VoidCallback onSeeHowItWorks,
  }) async {
    if (!await shouldOffer()) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    // Latched before the sheet is shown, not after it is answered: a user who
    // dismisses it by swiping, or who kills the app while it is open, has
    // still seen the offer.
    await markOffered();
    if (!context.mounted) {
      return;
    }
    final bool? seeHow = await CaptureOfferSheet.show(context);
    if (seeHow ?? false) {
      onSeeHowItWorks();
    }
  }
}
