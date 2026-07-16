import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../cubit/transaction_detail_cubit.dart';
import '../cubit/transaction_detail_state.dart';
import '../widgets/sheets/confirm_delete_transaction_sheet.dart';

/// HU-08: the enriched, reactive detail of a single transaction, with edit
/// and delete (HU-05) actions.
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({required this.onEdit, super.key});

  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionDetailCubit, TransactionDetailState>(
      // `current.deleted` alone would re-fire on every later emission (the
      // still-live watch stream re-queries once `deletedAt` is set and keeps
      // `deleted: true` via copyWith), double-popping past the list page.
      listenWhen: (previous, current) =>
          previous.deletePrompt != current.deletePrompt ||
          (!previous.deleted && current.deleted),
      listener: (context, state) async {
        if (state.deleted) {
          // Carries the id back to the list page so it can offer the same
          // "Deshacer" snackbar HU-05 promises regardless of where the
          // delete was triggered from — this page runs its own delete
          // through `TransactionDetailCubit`, entirely separate from
          // `TransactionsListCubit.deleteTransaction`, which is the only
          // place that otherwise knows how to show it.
          Navigator.of(context).pop(state.entry?.transaction.id);
          return;
        }
        if (state.deletePrompt) {
          final cubit = context.read<TransactionDetailCubit>();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => ConfirmDeleteTransactionSheet(
              onCancel: () {
                cubit.cancelDelete();
                Navigator.of(context).pop();
              },
              onConfirm: () {
                Navigator.of(context).pop();
                unawaited(cubit.confirmDelete());
              },
            ),
          );
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final entry = state.entry;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.transactionDetailTitle),
            actions: [
              if (entry != null) ...[
                IconButton(
                  onPressed: () => onEdit(entry.transaction.id),
                  tooltip: l10n.transactionDetailEdit,
                  icon: const Icon(LucideIcons.pencil),
                ),
                IconButton(
                  onPressed:
                      context.read<TransactionDetailCubit>().requestDelete,
                  tooltip: l10n.transactionDetailDelete,
                  icon: const Icon(LucideIcons.trash),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              TransactionDetailStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              TransactionDetailStatus.failure =>
                Center(child: Text(l10n.transactionsErrorTitle)),
              TransactionDetailStatus.ready when entry != null =>
                TransactionDetailBody(entry: entry),
              TransactionDetailStatus.ready => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}

class TransactionDetailBody extends StatelessWidget {
  const TransactionDetailBody({required this.entry, super.key});

  final TransactionWithDetails entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final transaction = entry.transaction;
    final money = const MoneyFormatter()
        .format(transaction.amountMinor, currencyCode: transaction.currency);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(money, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text(l10n.transactionDetailAccountLine(entry.accountName)),
        if (entry.transferAccountName != null)
          Text(l10n.transactionDetailTransferLine(entry.transferAccountName!)),
        if (entry.categoryName != null)
          Text(l10n.transactionDetailCategoryLine(entry.categoryName!)),
        if (transaction.note != null && transaction.note!.isNotEmpty)
          Text(l10n.transactionDetailNoteLine(transaction.note!)),
        if (entry.tags.isNotEmpty)
          Text(
            l10n.transactionDetailTagsLine(
              entry.tags.map((tag) => tag.name).join(', '),
            ),
          ),
        const SizedBox(height: 16),
        Text(l10n
            .transactionDetailSource(_sourceLabel(l10n, transaction.source))),
      ],
    );
  }

  /// HU-08 criterion 10: a legible label for every `TransactionSource`, even
  /// the ones no capture flow can produce yet.
  String _sourceLabel(AppLocalizations l10n, TransactionSource source) =>
      switch (source) {
        TransactionSource.manual => l10n.transactionSourceManual,
        TransactionSource.voice => l10n.transactionSourceVoice,
        TransactionSource.ocr => l10n.transactionSourceOcr,
        TransactionSource.notification => l10n.transactionSourceNotification,
        TransactionSource.imported => l10n.transactionSourceImported,
        TransactionSource.recurring => l10n.transactionSourceRecurring,
      };
}
