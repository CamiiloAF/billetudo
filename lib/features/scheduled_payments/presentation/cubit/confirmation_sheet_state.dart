import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';

enum ConfirmationSheetStatus {
  /// `load` has not been called yet — the sheet's owner always calls it right
  /// after opening, before the first frame with data renders.
  loading,
  ready,
  saving,
  confirmed,
  skipped,
  snoozed,
  failure,
}

/// State of the mandatory confirmation sheet (HU-03, criterion 7): the only
/// path that applies a pending occurrence to the balance.
///
/// `date`/`accountId`/`amountMinor` are editable and start prefilled from the
/// template's current values; `categoryId`/`note`/`type`/`currency` are
/// read-only, sourced straight from [source] for the UI to render. Editing
/// here never touches the template (criterion 8) — the use case only ever
/// receives these three fields.
class ConfirmationSheetState extends Equatable {
  const ConfirmationSheetState({
    this.status = ConfirmationSheetStatus.loading,
    this.source,
    this.date,
    this.accountId,
    this.accountName,
    this.amountMinor,
    this.pendingCountForTemplate = 1,
    this.failure,
  });

  factory ConfirmationSheetState.loaded(
    PendingScheduledOccurrence source, {
    int pendingCountForTemplate = 1,
  }) =>
      ConfirmationSheetState(
        status: ConfirmationSheetStatus.ready,
        source: source,
        date: source.occurrence.effectiveDate,
        accountId: source.scheduledPayment.accountId,
        accountName: source.accountName,
        amountMinor: source.scheduledPayment.amountMinor,
        pendingCountForTemplate: pendingCountForTemplate,
      );

  final ConfirmationSheetStatus status;

  final PendingScheduledOccurrence? source;

  final DateTime? date;
  final String? accountId;
  final String? accountName;
  final int? amountMinor;

  /// How many pending occurrences of the same template are currently
  /// unconfirmed — feeds the "Acumuladas" strip when 2+ (criterion 11: a
  /// template that missed several due dates still confirms one at a time,
  /// oldest first, but the user should see the backlog).
  final int pendingCountForTemplate;

  final Failure? failure;

  String get occurrenceId => source!.occurrence.id;
  String get scheduledPaymentId => source!.scheduledPayment.id;
  ScheduledPaymentType get type => source!.scheduledPayment.type;
  String get currency => source!.scheduledPayment.currency;
  String? get categoryName => source!.categoryName;
  String? get note => source!.scheduledPayment.note;
  String? get transferAccountName => source!.transferAccountName;
  bool get isTransfer => source!.scheduledPayment.isTransfer;

  bool get isReady =>
      status != ConfirmationSheetStatus.loading && source != null;
  bool get isSaving => status == ConfirmationSheetStatus.saving;

  ConfirmationSheetState copyWith({
    ConfirmationSheetStatus? status,
    DateTime? date,
    String? accountId,
    String? accountName,
    int? amountMinor,
    int? pendingCountForTemplate,
    Failure? failure,
  }) =>
      ConfirmationSheetState(
        status: status ?? this.status,
        source: source,
        date: date ?? this.date,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        amountMinor: amountMinor ?? this.amountMinor,
        pendingCountForTemplate:
            pendingCountForTemplate ?? this.pendingCountForTemplate,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        source,
        date,
        accountId,
        accountName,
        amountMinor,
        pendingCountForTemplate,
        failure,
      ];
}
