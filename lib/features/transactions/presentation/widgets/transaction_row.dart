import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';

/// A single row of the transaction list (HU-06): category/account, note,
/// date and the amount, signed and colored by [TransactionType].
class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.entry, required this.onTap, super.key});

  final TransactionWithDetails entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final transaction = entry.transaction;
    final title = entry.categoryName ??
        (transaction.isTransfer
            ? '${entry.accountName} → ${entry.transferAccountName ?? ''}'
            : entry.accountName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(transaction),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _amountLabel(transaction),
              style: theme.textTheme.titleMedium?.copyWith(
                color: _amountColor(colors, transaction.type),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Transaction transaction) {
    final note = transaction.note;
    final date = DateFormat.yMMMd('es_CO').format(transaction.date);
    return note == null || note.isEmpty ? date : '$date · $note';
  }

  String _amountLabel(Transaction transaction) {
    final formatted = const MoneyFormatter()
        .format(transaction.amountMinor, currencyCode: transaction.currency);
    return switch (transaction.type) {
      TransactionType.income => '+$formatted',
      TransactionType.expense => '-$formatted',
      TransactionType.transfer => formatted,
    };
  }

  Color _amountColor(AppColors colors, TransactionType type) => switch (type) {
        TransactionType.income => colors.incomeText,
        TransactionType.expense => colors.expenseText,
        TransactionType.transfer => colors.textPrimary,
      };
}
