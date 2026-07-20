import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_with_details.dart';

/// A single row of the transaction list (HU-06/`B3GGa`/`xAk6Y`): the
/// category's icon-wrap, its note/description, "Cuenta · Fecha" and the
/// amount, signed and colored by [TransactionType].
class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.entry, required this.onTap, super.key});

  final TransactionWithDetails entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final transaction = entry.transaction;
    final title = _title(entry, transaction);

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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

  /// The row's primary text (`ua7j7`, `B3GGa`/`xAk6Y`) is the transaction's
  /// note/description when the user wrote one — the category is conveyed by
  /// the icon-wrap's icon and color instead, never repeated as text here.
  /// Falls back to the category name, then to the account(s) involved, for
  /// transactions without a note (e.g. imported entries, or a transfer with
  /// no category).
  String _title(TransactionWithDetails entry, Transaction transaction) {
    final note = transaction.note;
    if (note != null && note.isNotEmpty) return note;
    return entry.categoryName ??
        (transaction.isTransfer
            ? '${entry.accountName} → ${entry.transferAccountName ?? ''}'
            : entry.accountName);
  }

  /// "Cuenta · Fecha" (`B3GGa`/`xAk6Y`). The note is never repeated here —
  /// it is already shown as the row's primary text via [_title].
  String _subtitle(TransactionWithDetails entry) {
    final transaction = entry.transaction;
    final date = DateFormat.yMMMd('es_CO').format(transaction.date);
    return transaction.isTransfer ? date : '${entry.accountName} · $date';
  }

  String _amountLabel(Transaction transaction) {
    final formatted = const MoneyFormatter().formatSymbol(
      transaction.amountMinor,
      currencyCode: transaction.currency,
    );
    return switch (transaction.type) {
      TransactionType.income => '+$formatted',
      // No minus sign on an expense: Pencil prints it unsigned and lets the
      // colour carry the meaning (only income is marked, with `+`).
      TransactionType.expense => formatted,
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
