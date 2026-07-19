import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';

/// A single row of the transaction list (HU-06/`B3GGa`/`xAk6Y`): the
/// category's icon-wrap, its name, "Cuenta · Fecha" and the amount, signed
/// and colored by [TransactionType].
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CategoryAppearance.softColorFor(
                  colors,
                  entry.categoryColor,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CategoryAppearance.iconFor(entry.categoryIcon),
                size: 20,
                color: CategoryAppearance.colorFor(colors, entry.categoryColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(entry),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
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

  /// "Cuenta · Fecha" (`B3GGa`/`xAk6Y`); the note, when there is one, still
  /// tags along so it is not lost from the list.
  String _subtitle(TransactionWithDetails entry) {
    final transaction = entry.transaction;
    final date = DateFormat.yMMMd('es_CO').format(transaction.date);
    final base = transaction.isTransfer ? date : '${entry.accountName} · $date';
    final note = transaction.note;
    return note == null || note.isEmpty ? base : '$base · $note';
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

  /// An expense reads in `$text-primary`, not red — red is reserved for
  /// destructive actions ("Eliminar"), never for a normal expense amount in
  /// the list (`B3GGa`/`xAk6Y`).
  Color _amountColor(AppColors colors, TransactionType type) => switch (type) {
        TransactionType.income => colors.incomeText,
        TransactionType.expense => colors.textPrimary,
        TransactionType.transfer => colors.textPrimary,
      };
}
