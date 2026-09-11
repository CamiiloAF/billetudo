import 'package:equatable/equatable.dart';

import 'capture_review_item.dart';

/// State of the "Pendientes de confirmar" block that opens the movements list
/// (`vNjim`).
///
/// Holds only what that block draws. It is deliberately separate from the
/// list's own state: a capture is not a `Transaction`, so it must not enter
/// `TransactionsListState.items`, where the grouping and the daily totals
/// would pick it up.
class PendingCapturesState extends Equatable {
  const PendingCapturesState({this.items = const <CaptureReviewItem>[]});

  /// Only captures that still resolve to an existing account: without one the
  /// row could not say which account it belongs to, and the movements list is
  /// organised by account. Those captures do not disappear — they stay in the
  /// Avisos centre, which is where an unassigned capture belongs.
  final List<CaptureReviewItem> items;

  bool get isEmpty => items.isEmpty;

  PendingCapturesState copyWith({List<CaptureReviewItem>? items}) =>
      PendingCapturesState(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
