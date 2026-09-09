import '../../../transactions/presentation/cubit/capture_prefill.dart';
import '../cubit/capture_review_item.dart';

/// Turns a reviewed capture into the seed of the ordinary transaction form
/// (HU-05).
///
/// Lives in `presentation/utils` rather than in either cubit because both
/// surfaces that can dispatch a capture — the Avisos centre and the ghost
/// block in Movimientos — must hand over exactly the same thing. A second
/// mapping is how "el mismo formulario, pre-llenado" quietly becomes two
/// slightly different forms.
CapturePrefill capturePrefillFor(CaptureReviewItem item) {
  final capture = item.capture;
  return CapturePrefill(
    captureId: capture.id,
    amountMinor: capture.amountMinor,
    currency: capture.currency,
    type: capture.entryType,
    postedAt: capture.postedAt,
    accountId: capture.suggestedAccountId,
    note: capture.merchantRaw,
    categoryId: capture.suggestedCategoryId,
  );
}
