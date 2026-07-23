import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/widgets/info_card.dart';
import '../../../accounts/presentation/widgets/info_row.dart';
import '../../../transactions/presentation/widgets/transaction_header_button.dart';
import '../../domain/entities/scheduled_history_entry.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_detail.dart';
import '../cubit/scheduled_payment_detail_cubit.dart';
import '../cubit/scheduled_payment_detail_state.dart';
import '../utils/scheduled_payment_format.dart';
import '../widgets/scheduled_payment_detail_badge.dart';
import '../widgets/scheduled_payment_detail_tags_row.dart';
import '../widgets/scheduled_payment_hero_card.dart';
import '../widgets/scheduled_payment_history_row.dart';
import '../widgets/scheduled_payment_skipped_history_row.dart';
import '../widgets/sheets/confirmation_sheet.dart';
import '../widgets/sheets/delete_scheduled_payment_sheet.dart';
import '../widgets/sheets/scheduled_payment_detail_actions_sheet.dart';
import '../widgets/sheets/snooze_sheet.dart';

/// The hybrid "próximo pago + configuración" detail (HU-05), its expandable
/// history in place (criterion 13), and the ⋮ menu (edit, posponer, eliminar,
/// criterion 12).
class ScheduledPaymentDetailPage extends StatelessWidget {
  const ScheduledPaymentDetailPage({
    required this.onEdit,
    required this.onOpenTransaction,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Navigates to the transaction detail page (from a history row) and
  /// resolves with whatever it popped with (the deleted transaction's id, or
  /// `null`).
  final Future<String?> Function(String id) onOpenTransaction;

  /// Awaits the detail page's navigation, then — if it deleted something —
  /// offers HU-05's "Deshacer" snackbar via [ScheduledPaymentDetailCubit].
  Future<void> _openTransaction(BuildContext context, String id) async {
    final deletedId = await onOpenTransaction(id);
    if (deletedId != null && context.mounted) {
      context
          .read<ScheduledPaymentDetailCubit>()
          .notifyExternalDelete(deletedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ScheduledPaymentDetailCubit,
        ScheduledPaymentDetailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.pendingUndoSnoozeOccurrenceId !=
              current.pendingUndoSnoozeOccurrenceId ||
          // A re-snooze of the *same* occurrence keeps the same id, so the id
          // alone would not re-fire the "Deshacer" snackbar (the exact 30→31
          // repro). The pre-snooze date strictly changes on every snooze, so
          // comparing it guarantees each snooze re-triggers the listener.
          previous.pendingUndoSnoozePreviousDate !=
              current.pendingUndoSnoozePreviousDate ||
          (previous.pendingUndoRecoverOccurrenceId !=
                  current.pendingUndoRecoverOccurrenceId &&
              current.pendingUndoRecoverOccurrenceId != null) ||
          (previous.pendingUndoDeleteTransactionId !=
                  current.pendingUndoDeleteTransactionId &&
              current.pendingUndoDeleteTransactionId != null) ||
          (previous.confirmNowOccurrence != current.confirmNowOccurrence &&
              current.confirmNowOccurrence != null) ||
          (previous.failure != current.failure &&
              current.failure != null &&
              current.status == ScheduledPaymentDetailStatus.ready),
      listener: (context, state) {
        if (state.status == ScheduledPaymentDetailStatus.closed) {
          Navigator.of(context).pop();
          return;
        }
        final cubit = context.read<ScheduledPaymentDetailCubit>();
        // An action failure while the screen stays usable (e.g. "Confirmar
        // ahora" had nothing left to confirm): surface it instead of failing
        // silently. A load failure sets `status = failure` and is handled by
        // the error screen in `builder`, not here.
        if (state.failure != null &&
            state.status == ScheduledPaymentDetailStatus.ready) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.scheduledPaymentDetailConfirmNowError),
              ),
            );
          return;
        }
        final confirmNowOccurrence = state.confirmNowOccurrence;
        if (confirmNowOccurrence != null) {
          // "Confirmar ahora" (`docs/bugfixes.md` point 1): hands the freshly
          // materialized occurrence straight to the same mandatory
          // `ConfirmationSheet` the due-date tap already opens — no separate
          // one-tap shortcut, same HU-03 invariant. If the user posponed it
          // there, offer the same "Deshacer" the ⋮ → Posponer path does, so
          // both entry points behave identically.
          final occurrence = confirmNowOccurrence.occurrence;
          unawaited(
            ConfirmationSheet.show(context, source: confirmNowOccurrence)
                .then((result) {
              unawaited(cubit.dismissConfirmNow());
              if (result == ConfirmationSheetResult.snoozed) {
                // "Confirmar ahora" materialized this occurrence as a fresh
                // `pending` row: the snooze updates it (never creates), so undo
                // clears the snooze back to that pending state.
                cubit.notifySnoozed(
                  occurrence.id,
                  wasCreated: false,
                  previousSnoozedToDate: occurrence.snoozedToDate,
                );
              }
            }),
          );
          return;
        }
        final undoSnoozeId = state.pendingUndoSnoozeOccurrenceId;
        if (undoSnoozeId != null) {
          final messenger = ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar();
          final controller = messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.scheduledUndoSnoozeMessage),
              action: SnackBarAction(
                label: l10n.transactionsUndoAction,
                onPressed: cubit.undoSnooze,
              ),
              duration: const Duration(seconds: 5),
              persist: false,
            ),
          );
          // Clear the one-shot trigger once the snackbar closes on its own, so
          // a stale occurrence id never lingers in state (it would suppress the
          // next snooze's snackbar, which keys off this field changing).
          unawaited(
            controller.closed.then((reason) {
              if (reason != SnackBarClosedReason.action) {
                cubit.dismissUndoSnooze();
              }
            }),
          );
          return;
        }
        final undoRecoverId = state.pendingUndoRecoverOccurrenceId;
        if (undoRecoverId != null) {
          // "Recuperar" (page spec, Fase 2): the occurrence is already back to
          // pending; offer the reversible "Pago recuperado · Deshacer" (which
          // re-skips), same one-shot pattern as the snooze undo.
          final messenger = ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar();
          final controller = messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.scheduledRecoverMessage),
              action: SnackBarAction(
                label: l10n.transactionsUndoAction,
                onPressed: cubit.undoRecover,
              ),
              duration: const Duration(seconds: 5),
              persist: false,
            ),
          );
          unawaited(
            controller.closed.then((reason) {
              if (reason != SnackBarClosedReason.action) {
                cubit.dismissUndoRecover();
              }
            }),
          );
          return;
        }
        final undoDeleteId = state.pendingUndoDeleteTransactionId;
        if (undoDeleteId != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.transactionsUndoDeletedMessage),
                action: SnackBarAction(
                  label: l10n.transactionsUndoAction,
                  onPressed: cubit.undoDelete,
                ),
                persist: false,
              ),
            );
        }
      },
      builder: (context, state) {
        final detail = state.detail;
        final colors = context.colors;
        return Scaffold(
          appBar: AppBar(
            // `OY2Kj`: same header vocabulary as the list — `arrow-left` and
            // the ⋮ both sit inside a `$muted` circle.
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: TransactionHeaderButton(
                icon: LucideIcons.arrowLeft,
                background: colors.muted,
                foreground: colors.textPrimary,
                tooltip: l10n.commonBack,
                onPressed: Navigator.of(context).pop,
              ),
            ),
            title: Text(l10n.scheduledPaymentDetailTitle),
            actions: [
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TransactionHeaderButton(
                    icon: LucideIcons.ellipsisVertical,
                    background: colors.muted,
                    foreground: colors.textPrimary,
                    tooltip: l10n.commonMoreActions,
                    onPressed: () => _openActions(context, detail),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              ScheduledPaymentDetailStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ScheduledPaymentDetailStatus.failure =>
                Center(child: Text(l10n.scheduledPaymentsErrorTitle)),
              ScheduledPaymentDetailStatus.closed => const SizedBox.shrink(),
              ScheduledPaymentDetailStatus.ready when detail != null =>
                ScheduledPaymentDetailBody(
                  detail: detail,
                  state: state,
                  onOpenTransaction: (id) => _openTransaction(context, id),
                ),
              ScheduledPaymentDetailStatus.ready => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }

  Future<void> _openActions(
    BuildContext context,
    ScheduledPaymentDetail detail,
  ) {
    final cubit = context.read<ScheduledPaymentDetailCubit>();
    // HU-07: posponer moves *one* occurrence without touching the cadence.
    // A `once` template has no cadence, so moving its date is editing the
    // template (HU-05), not snoozing — hence Pencil's `nLkvf`, the ⋮ menu
    // without Posponer.
    final canSnooze = !detail.scheduledPayment.isDeleted &&
        detail.scheduledPayment.frequency != ScheduledPaymentFrequency.once;
    return ScheduledPaymentDetailActionsSheet.show(
      context,
      canSnooze: canSnooze,
      templateName: _templateName(context, detail),
      onSnooze:
          canSnooze ? () => unawaited(_openSnooze(context, detail)) : null,
      onEdit: () => onEdit(detail.scheduledPayment.id),
      onDelete: () => unawaited(
        DeleteScheduledPaymentSheet.show(context,
            onConfirm: cubit.confirmDelete),
      ),
    );
  }

  Future<void> _openSnooze(
    BuildContext context,
    ScheduledPaymentDetail detail,
  ) async {
    final cubit = context.read<ScheduledPaymentDetailCubit>();
    final result = await SnoozeSheet.show(
      context,
      scheduledPaymentId: detail.scheduledPayment.id,
      occurrenceDate: detail.pendingOccurrence?.occurrence.occurrenceDate ??
          detail.scheduledPayment.nextDate,
      templateName: _templateName(context, detail),
      isTransfer: detail.scheduledPayment.isTransfer,
      categoryIcon: detail.categoryIcon,
      categoryColor: detail.categoryColor,
    );
    if (result != null) {
      // The only path that can materialize a brand-new occurrence (the
      // not-yet-due next payment): the repository reports `wasCreated` and the
      // previous snoozed date so undo reverses exactly one step.
      cubit.notifySnoozed(
        result.occurrence.id,
        wasCreated: result.wasCreated,
        previousSnoozedToDate: result.previousSnoozedToDate,
      );
    }
  }

  String _templateName(BuildContext context, ScheduledPaymentDetail detail) =>
      ScheduledPaymentFormat.templateName(
        note: detail.scheduledPayment.note,
        isTransfer: detail.scheduledPayment.isTransfer,
        accountName: detail.accountName,
        transferAccountName: detail.transferAccountName,
        fallback: AppLocalizations.of(context).scheduledPaymentUntitled,
      );
}

class ScheduledPaymentDetailBody extends StatelessWidget {
  const ScheduledPaymentDetailBody({
    required this.detail,
    required this.state,
    required this.onOpenTransaction,
    super.key,
  });

  final ScheduledPaymentDetail detail;
  final ScheduledPaymentDetailState state;
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final payment = detail.scheduledPayment;
    final pending = detail.pendingOccurrence;
    final templateName = ScheduledPaymentFormat.templateName(
      note: payment.note,
      isTransfer: payment.isTransfer,
      accountName: detail.accountName,
      transferAccountName: detail.transferAccountName,
      fallback: l10n.scheduledPaymentUntitled,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        ScheduledPaymentIdentityStrip(
          payment: payment,
          accountName: detail.accountName,
          transferAccountName: detail.transferAccountName,
          categoryName: detail.categoryName,
          categoryIcon: detail.categoryIcon,
          categoryColor: detail.categoryColor,
        ),
        if (payment.isDeleted)
          ScheduledPaymentDetailBadge(label: l10n.scheduledInactiveBadge),
        const SizedBox(height: 16),
        ScheduledPaymentHeroCard(
          payment: payment,
          pending: pending,
          nextPaymentDate: detail.nextPaymentDate,
          executed: detail.onceAlreadyGenerated,
          onTapPending: () async {
            final result =
                await ConfirmationSheet.show(context, source: pending!);
            if (result == ConfirmationSheetResult.snoozed && context.mounted) {
              // An existing (vencida) occurrence: the snooze updates it, so
              // undo steps back to whatever snoozed date it held before (null
              // when it was still `pending`).
              context.read<ScheduledPaymentDetailCubit>().notifySnoozed(
                    pending.occurrence.id,
                    wasCreated: false,
                    previousSnoozedToDate: pending.occurrence.snoozedToDate,
                  );
            }
          },
          onConfirmNow: () =>
              context.read<ScheduledPaymentDetailCubit>().confirmNow(),
        ),
        const SizedBox(height: 16),
        InfoCard(
          children: [
            InfoRow(
              label: l10n.scheduledPaymentDetailModeLabel,
              value: payment.requiresConfirmation
                  ? l10n.scheduledPaymentDetailModeManual
                  : l10n.scheduledPaymentDetailModeAutomatic,
            ),
            InfoRow(
              label: l10n.scheduledPaymentDetailAccountLabel,
              value: payment.isTransfer
                  ? '${detail.accountName} → ${detail.transferAccountName ?? ''}'
                  : detail.accountName,
            ),
            InfoRow(
              label: l10n.scheduledPaymentDetailStatusLabel,
              // The "Estado" row is the slot the design models for this: an
              // active template with an occurrence still to confirm reads
              // "Pendiente de confirmar" here, never as a second pill in the
              // hero (which already owns the countdown pill).
              value: switch ((detail.isActive, payment.isDeleted)) {
                (true, _) when pending != null => l10n.scheduledPendingBadge,
                (true, _) => l10n.scheduledPaymentDetailStatusActive,
                (false, true) => l10n.scheduledInactiveBadge,
                // `Eyold`: the one-off already fired — terminada, not
                // inactiva (nobody deleted it) and never activa.
                (false, false) => l10n.scheduledPaymentDetailStatusFinished,
              },
            ),
            if (!payment.isTransfer)
              ScheduledPaymentDetailTagsRow(tags: detail.tags),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.scheduledPaymentDetailHistoryTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (state.history.isEmpty)
          Text(
            l10n.scheduledPaymentDetailHistoryEmpty,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary),
          )
        else
          for (final entry in state.history) ...[
            switch (entry) {
              ScheduledConfirmedHistoryEntry(:final transaction) =>
                ScheduledPaymentHistoryRow(
                  transaction: transaction,
                  name: templateName,
                  accountName: detail.accountName,
                  isTransfer: payment.isTransfer,
                  categoryIcon: detail.categoryIcon,
                  categoryColor: detail.categoryColor,
                  onTap: () => onOpenTransaction(transaction.id),
                ),
              ScheduledSkippedHistoryEntry() => ScheduledSkippedHistoryRow(
                  name: templateName,
                  date: entry.date,
                  amountMinor: entry.amountMinor,
                  currency: entry.currency,
                  onRecover: () => context
                      .read<ScheduledPaymentDetailCubit>()
                      .recoverSkipped(entry.occurrenceId),
                ),
            },
            const SizedBox(height: 8),
          ],
        if (state.hasMoreHistory)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: state.loadingMoreHistory
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: TextButton(
                      onPressed: () => context
                          .read<ScheduledPaymentDetailCubit>()
                          .loadMoreHistory(),
                      child: Text(
                        l10n.scheduledPaymentDetailHistorySeeAll(
                            state.historyTotalCount),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
