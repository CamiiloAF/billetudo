import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/budget_activity_item.dart';

/// One row of a budget's period activity (HU-04). Mirrors the Transactions
/// `Transaction Row` look — every item here is an expense (transfers are never
/// budget spend), so the amount is always shown as a negative expense.
class BudgetActivityRow extends StatelessWidget {
  const BudgetActivityRow({required this.item, super.key});

  final BudgetActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _amountLabel(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.expenseText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Every budget activity item is an expense, so it always renders negative.
  String _amountLabel() {
    final amount = const MoneyFormatter()
        .format(item.amountMinor, currencyCode: item.currency);
    return '-$amount';
  }

  String _subtitle() {
    final date = DateFormat.yMMMd('es_CO').format(item.date);
    final note = item.note;
    return note == null || note.isEmpty ? date : '$date · $note';
  }
}
