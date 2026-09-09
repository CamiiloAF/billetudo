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

  /// How many captures the screen shows before collapsing the rest behind
  /// the overflow row (`sCJCZ`). Only applied when the notices section also
  /// has content: the cap exists to keep both sections visible without
  /// scrolling on a 390x844 phone, and what gets cut is always the captures,
  /// never the notices.
  static const int collapsedCaptureLimit = 2;

  final NoticesStatus status;
  final List<CaptureReviewItem> captures;

  /// Whether any issuer of the catalog is switched on (HU-02). `false` means
  /// the captures section can never fill, so the empty screen explains that
  /// instead of saying "todo al día". Defaults to `true` so the screen never
  /// flashes the "elige apps" copy at a user who does have issuers on, just
  /// because that stream landed a beat later.
  final bool hasEnabledIssuers;

  /// Set by the overflow row: shows every capture instead of the first
  /// [collapsedCaptureLimit].
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

  /// Nothing at all to review: the single full-screen empty state.
  bool get isEmpty =>
      status == NoticesStatus.ready && !hasNotices && !hasCaptures;

  /// The empty state that explains *why* the inbox will stay empty, rather
  /// than the neutral "Todo al día". Only when there is genuinely nothing
  /// else on screen.
  bool get isEmptyWithoutIssuers => isEmpty && !hasEnabledIssuers;

  /// The captures actually rendered. Capped only while the notices section
  /// is competing for the same viewport.
  List<CaptureReviewItem> get visibleCaptures =>
      capturesExpanded || !hasNotices || captures.length <= collapsedCaptureLimit
          ? captures
          : captures.sublist(0, collapsedCaptureLimit);

  /// How many captures the overflow row stands for. `0` hides the row.
  int get hiddenCaptureCount => captures.length - visibleCaptures.length;

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
        discardedId: clearDiscardedId ? null : (discardedId ?? this.discardedId),
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
