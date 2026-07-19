import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/widgets/info_card.dart';
import '../../../accounts/presentation/widgets/info_row.dart';
import '../../domain/entities/scheduled_payment_detail.dart';
import '../cubit/scheduled_payment_detail_cubit.dart';
import '../cubit/scheduled_payment_detail_state.dart';
import '../utils/scheduled_payment_format.dart';
import '../widgets/scheduled_payment_detail_badge.dart';
import '../widgets/scheduled_payment_detail_tags_row.dart';
import '../widgets/scheduled_payment_hero_card.dart';
import '../widgets/scheduled_payment_history_row.dart';
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
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ScheduledPaymentDetailCubit,
        ScheduledPaymentDetailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.pendingUndoSnoozeOccurrenceId !=
              current.pendingUndoSnoozeOccurrenceId,
      listener: (context, state) {
        if (state.status == ScheduledPaymentDetailStatus.closed) {
          Navigator.of(context).pop();
          return;
        }
        final undoId = state.pendingUndoSnoozeOccurrenceId;
        if (undoId != null) {
          final cubit = context.read<ScheduledPaymentDetailCubit>();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
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
        }
      },
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.scheduledPaymentDetailTitle),
            actions: [
              if (detail != null)
                IconButton(
                  icon: const Icon(LucideIcons.ellipsisVertical),
                  onPressed: () => _openActions(context, detail),
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
                  onOpenTransaction: onOpenTransaction,
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
    final canSnooze = !detail.scheduledPayment.isDeleted;
    return ScheduledPaymentDetailActionsSheet.show(
      context,
      canSnooze: canSnooze,
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
      templateTitle: ScheduledPaymentFormat.templateTitle(
        categoryName: detail.categoryName,
        isTransfer: detail.scheduledPayment.isTransfer,
        accountName: detail.accountName,
        transferAccountName: detail.transferAccountName,
      ),
    );
    if (result != null) {
      cubit.notifySnoozed(result.id);
    }
  }
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
          onTapPending: () => ConfirmationSheet.show(context, source: pending!),
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
              value: payment.isDeleted
                  ? l10n.scheduledInactiveBadge
                  : l10n.scheduledPaymentDetailStatusActive,
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
            ScheduledPaymentHistoryRow(
              transaction: entry,
              onTap: () => onOpenTransaction(entry.id),
            ),
            const SizedBox(height: 8),
          ],
        if (state.hasMoreHistory)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: state.loadingMoreHistory
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: () => context
                        .read<ScheduledPaymentDetailCubit>()
                        .loadMoreHistory(),
                    child: Text(
                      l10n.scheduledPaymentDetailHistorySeeAll(
                          state.historyTotalCount),
                    ),
                  ),
          ),
      ],
    );
  }
}
