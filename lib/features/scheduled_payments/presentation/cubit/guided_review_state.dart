import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';

enum GuidedReviewStatus { loading, ready, saving, finished, failure }

/// State of "Revisar todas" (HU-03): every pending occurrence reviewed one
/// at a time, in order — never a single "apply-all" action, so each one
/// still goes through the same mandatory verification as the standalone
/// sheet (criterion 7).
class GuidedReviewState extends Equatable {
  const GuidedReviewState({
    this.status = GuidedReviewStatus.loading,
    this.queue = const <PendingScheduledOccurrence>[],
    this.index = 0,
    this.date,
    this.accountId,
    this.accountName,
    this.amountMinor,
    this.resolvedCount = 0,
    this.pendingCountForTemplate = 1,
    this.failure,
  });

  final GuidedReviewStatus status;

  /// Snapshot of the pending occurrences at the moment the review started —
  /// resolved ones are not removed from it, only skipped over by [index], so
  /// the "N de M" counter stays stable through the flow.
  final List<PendingScheduledOccurrence> queue;

  final int index;

  final DateTime? date;
  final String? accountId;
  final String? accountName;
  final int? amountMinor;

  final int resolvedCount;

  /// How many pending occurrences in [queue] share the current occurrence's
  /// template — same purpose as `ConfirmationSheetState.pendingCountForTemplate`,
  /// feeding the "Acumuladas" strip while guided review is open.
  final int pendingCountForTemplate;

  final Failure? failure;

  bool get isReady => status == GuidedReviewStatus.ready;
  bool get isSaving => status == GuidedReviewStatus.saving;
  bool get isFinished => status == GuidedReviewStatus.finished;

  PendingScheduledOccurrence? get current =>
      index < queue.length ? queue[index] : null;

  int get total => queue.length;

  /// 1-based, for "N de M".
  int get position => index + 1;

  ScheduledPaymentType? get type => current?.scheduledPayment.type;
  String? get currency => current?.scheduledPayment.currency;
  String? get categoryName => current?.categoryName;
  String? get note => current?.scheduledPayment.note;
  String? get transferAccountName => current?.transferAccountName;
  bool get isTransfer => current?.scheduledPayment.isTransfer ?? false;

  GuidedReviewState copyWith({
    GuidedReviewStatus? status,
    List<PendingScheduledOccurrence>? queue,
    int? index,
    DateTime? date,
    String? accountId,
    String? accountName,
    int? amountMinor,
    int? resolvedCount,
    int? pendingCountForTemplate,
    Failure? failure,
  }) =>
      GuidedReviewState(
        status: status ?? this.status,
        queue: queue ?? this.queue,
        index: index ?? this.index,
        date: date ?? this.date,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        amountMinor: amountMinor ?? this.amountMinor,
        resolvedCount: resolvedCount ?? this.resolvedCount,
        pendingCountForTemplate:
            pendingCountForTemplate ?? this.pendingCountForTemplate,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        queue,
        index,
        date,
        accountId,
        accountName,
        amountMinor,
        resolvedCount,
        pendingCountForTemplate,
        failure,
      ];
}
