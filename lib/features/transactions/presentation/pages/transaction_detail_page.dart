import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../cubit/transaction_detail_cubit.dart';
import '../cubit/transaction_detail_state.dart';
import '../widgets/detail_actions_row.dart';
import '../widgets/detail_amount_hero.dart';
import '../widgets/sheets/confirm_delete_transaction_sheet.dart';
import '../widgets/transaction_detail_info_card.dart';
import '../widgets/transaction_detail_tags_section.dart';
import '../widgets/transaction_header_button.dart';

/// HU-08: the enriched, reactive detail of a single transaction (`Of2sW`
/// expense, `s4Wsu5` income, `xNp8g` transfer), with edit and delete (HU-05)
/// actions.
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
          await ConfirmDeleteTransactionSheet.show(
            context,
            onCancel: () {
              cubit.cancelDelete();
              Navigator.of(context).pop();
            },
            onConfirm: () {
              Navigator.of(context).pop();
              unawaited(cubit.confirmDelete());
            },
          );
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        final entry = state.entry;
        return Scaffold(
          appBar: AppBar(
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
            title: Text(
              _titleFor(l10n, entry?.transaction.type),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            // Balances the leading back button so the title stays centered.
            // Not a real "more options" button (that duplicated Editar/
            // Eliminar, already visible in `DetailActionsRow` below).
            actions: const [SizedBox(width: 44)],
          ),
          body: SafeArea(
            child: switch (state.status) {
              TransactionDetailStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              TransactionDetailStatus.failure =>
                Center(child: Text(l10n.transactionsErrorTitle)),
              TransactionDetailStatus.ready when entry != null =>
                TransactionDetailBody(
                  entry: entry,
                  onEdit: () => onEdit(entry.transaction.id),
                  onDelete:
                      context.read<TransactionDetailCubit>().requestDelete,
                ),
              TransactionDetailStatus.ready => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }

  String _titleFor(AppLocalizations l10n, TransactionType? type) =>
      switch (type) {
        TransactionType.income => l10n.transactionDetailTitleIncome,
        TransactionType.transfer => l10n.transactionDetailTitleTransfer,
        TransactionType.expense || null => l10n.transactionDetailTitleExpense,
      };
}

class TransactionDetailBody extends StatelessWidget {
  const TransactionDetailBody({
    required this.entry,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final TransactionWithDetails entry;

  /// Null in tests that only assert the read-only content.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final transaction = entry.transaction;
    final money = const MoneyFormatter()
        .format(transaction.amountMinor, currencyCode: transaction.currency);
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        DetailAmountHero(
          type: transaction.type,
          amountLabel: money,
          subtitle: transaction.isTransfer
              ? l10n.transactionDetailTransferSubtitle
              : entry.categoryName ?? '',
          categoryIcon: entry.categoryIcon,
        ),
        const SizedBox(height: 20),
        TransactionDetailInfoCard(entry: entry, locale: locale),
        if (!transaction.isTransfer && entry.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          TransactionDetailTagsSection(tags: entry.tags),
        ],
        const SizedBox(height: 20),
        if (onEdit != null && onDelete != null)
          DetailActionsRow(
            editLabel: l10n.commonEdit,
            deleteLabel: l10n.transactionDetailDeleteLink,
            onEdit: onEdit!,
            onDelete: onDelete!,
          ),
      ],
    );
  }
}
