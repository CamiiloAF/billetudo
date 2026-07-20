import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_activity_item.dart';

/// One row of a budget's period activity (HU-04). Structurally the shared
/// `Transaction Row` (`DKJaf`) as the detail instances it: a 44pt icon-wrap in
/// the category's soft tone, "Cuenta · Fecha" underneath the title, and the
/// amount on the right — no card, no border. The rows sit straight on
/// `$background` inside the activity section (`NloPT/Abx0H`).
///
/// Tappable, same as `Transaction Row`: opens the real transaction's detail.
class BudgetActivityRow extends StatelessWidget {
  const BudgetActivityRow({
    required this.item,
    required this.onTap,
    super.key,
  });

  final BudgetActivityItem item;

  /// Called with [item.id] (the real `Transaction` id) to open its detail.
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onTap(item.id),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  CategoryAppearance.softColorFor(colors, item.categoryColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              CategoryAppearance.iconFor(item.categoryIcon),
              size: 20,
              color: CategoryAppearance.colorFor(colors, item.categoryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            _amountLabel(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Signed, and in `$text-primary` (not red) — the deliberate exception to the
  /// app-wide rule that an expense renders unsigned. In the Transactions list a
  /// row can be income, expense or transfer, so the sign would be noise; here
  /// every row is an expense of the *same* budget sitting under an accumulated
  /// total, and the `-` is what marks each one as a subtraction from the period
  /// rather than a running balance. Verified node by node against
  /// `NloPT/U6y9n/a1Pwa`, `rmROV`, `oD0A1`, `p4qBp` and their twins in `DN0GV`
  /// and `QLn6w`: all 12 read `-$X` in `$text-primary`. Do not "fix" this back
  /// to unsigned.
  String _amountLabel() {
    final amount = const MoneyFormatter()
        .formatSymbol(item.amountMinor, currencyCode: item.currency);
    return '-$amount';
  }

  /// "Cuenta · Fecha" (`DKJaf/pjX7P`); the note tags along when there is one so
  /// it is not lost from the list.
  String _subtitle() {
    final date = DateFormat.yMMMd('es_CO').format(item.date);
    final base = '${item.accountName} · $date';
    final note = item.note;
    return note == null || note.isEmpty ? base : '$base · $note';
  }
}
