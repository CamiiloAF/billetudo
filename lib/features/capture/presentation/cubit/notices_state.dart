import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'capture_review_item.dart';

enum NoticesStatus { loading, ready, failure }

/// State of the Avisos centre (`Bk8zW`), the full screen behind Home's bell.
///
/// Two sections live here: "Avisos" (scheduled charges, goals reached —
/// owned by another branch, hence [hasNotices] being a hardcoded `false`
/// placeholder for now) and "Capturas por confirmar" (HU-04/HU-05). **Each
/// section renders only if it has content**, and when neither does the screen
/// shows a single empty state instead of orphan headers.
class NoticesState extends Equatable {
  const NoticesState({
    this.status = NoticesStatus.loading,
    this.captures = const <CaptureReviewItem>[],
    this.hasEnabledIssuers = true,
    this.capturesExpanded = false,
    this.discardedId,
    this.failure,
  });

  /// Cap when both sections have content (`bXnXo`, the measured worst case):
  /// each section shows at most 2 elements plus its footer row (`YliJD`).
  /// What gets cut is always the captures, never the notices.
  static const int bothSectionsCaptureLimit = 2;

  /// Cap when captures are the only section on screen and none of them is a
  /// possible-duplicate card (`E3DGD`'s general case).
  static const int soloCaptureLimit = 4;

  /// Cap when captures are the only section AND the list includes a possible
  /// duplicate (`EqRlj`, 299px, ~3.7 ordinary cards): that one card alone
  /// eats the budget four would need, so the cap drops to 3 and the footer
  /// row is always shown — measured in `E91A7T`, not estimated.
  static const int soloCaptureLimitWithDuplicate = 3;

  final NoticesStatus status;
  final List<CaptureReviewItem> captures;

  /// Whether any issuer of the catalog is switched on (HU-02). `false` means
  /// the captures section can never fill, so the empty screen explains that
  /// instead of saying "todo al día". Defaults to `true` so the screen never
  /// flashes the "elige apps" copy at a user who does have issuers on, just
  /// because that stream landed a beat later.
  final bool hasEnabledIssuers;

  /// Set by the block-action row: shows every capture instead of the first
  /// [captureLimit].
  final bool capturesExpanded;

  /// The capture just discarded, so the page can offer "Deshacer". `null`
  /// once the snackbar is shown or the undo runs.
  final String? discardedId;

  final Failure? failure;

  bool get isLoading => status == NoticesStatus.loading;

  /// Placeholder for the notices section, owned by `feat/local-notifications`.
  /// Wired as a getter rather than a field so that branch adds its list here
  /// without this one guessing its shape.
  bool get hasNotices => false;

  bool get hasCaptures => captures.isNotEmpty;

  /// Whether the queue includes the expensive possible-duplicate card, which
  /// alone justifies dropping the solo cap from 4 to 3.
  bool get _hasDuplicateCapture => captures.any((item) => item.hasDuplicate);

  /// The cap currently in force, chosen by which sections compete for the
  /// viewport and by whether a possible-duplicate card is in the queue.
  int get captureLimit {
    if (hasNotices) {
      return bothSectionsCaptureLimit;
    }
    return _hasDuplicateCapture
        ? soloCaptureLimitWithDuplicate
        : soloCaptureLimit;
  }

  /// Nothing at all to review: the single full-screen empty state.
  bool get isEmpty =>
      status == NoticesStatus.ready && !hasNotices && !hasCaptures;

  /// The empty state that explains *why* the inbox will stay empty, rather
  /// than the neutral "Todo al día". Only when there is genuinely nothing
  /// else on screen.
  bool get isEmptyWithoutIssuers => isEmpty && !hasEnabledIssuers;

  /// The captures actually rendered, per [captureLimit].
  List<CaptureReviewItem> get visibleCaptures =>
      capturesExpanded || captures.length <= captureLimit
          ? captures
          : captures.sublist(0, captureLimit);

  /// How many captures stay off screen behind the block-action row
  /// (`YliJD`, "Revisar las N capturas"). `0` when everything fits.
  int get hiddenCaptureCount => captures.length - visibleCaptures.length;

  /// Whether the block-action row shows. Normally only when something is
  /// actually hidden, but a possible-duplicate card in a captures-only queue
  /// always earns the row — even at exactly [soloCaptureLimitWithDuplicate]
  /// items — because that card alone is worth routing through the guided,
  /// one-by-one review rather than resolving inline.
  bool get showCaptureBlockRow =>
      !capturesExpanded &&
      (hiddenCaptureCount > 0 || (!hasNotices && _hasDuplicateCapture));

  NoticesState copyWith({
    NoticesStatus? status,
    List<CaptureReviewItem>? captures,
    bool? hasEnabledIssuers,
    bool? capturesExpanded,
    String? discardedId,
    bool clearDiscardedId = false,
    Failure? failure,
  }) =>
      NoticesState(
        status: status ?? this.status,
        captures: captures ?? this.captures,
        hasEnabledIssuers: hasEnabledIssuers ?? this.hasEnabledIssuers,
        capturesExpanded: capturesExpanded ?? this.capturesExpanded,
        discardedId:
            clearDiscardedId ? null : (discardedId ?? this.discardedId),
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        captures,
        hasEnabledIssuers,
        capturesExpanded,
        discardedId,
        failure,
      ];
}
