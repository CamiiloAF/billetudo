import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/presentation/utils/transaction_amount_presentation.dart';

/// A single flat row of the Home's recent-activity feed (HU-05): category
/// icon + title + "account · date" + amount.
///
/// It is intentionally a flat row (no surface card) — the design's
/// `Transaction Row` for the Home is flat, which is why its skeleton
/// (`RecentActivitySkeletonRow`) is flat too. Amount coloring follows the
/// brand tone: expense in `text-primary` (never red), income in `income-text`,
/// transfer neutral (HU-05).
class RecentActivityRow extends StatelessWidget {
  const RecentActivityRow(
      {required this.entry, required this.onTap, super.key});

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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CategoryAvatar(entry: entry),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // `Transaction Row`'s `Name` (`ua7j7`) is 15/600.
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(context, transaction),
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
              transactionAmountLabel(transaction),
              style: theme.textTheme.titleMedium?.copyWith(
                color: transactionAmountColor(colors, transaction.type),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Note first (matches `TransactionRow` on the Movimientos list), falling
  /// back to the category name, then the account(s) involved.
  String _title(TransactionWithDetails entry, Transaction transaction) {
    final note = transaction.note;
    if (note != null && note.isNotEmpty) return note;
    return entry.categoryName ??
        (transaction.isTransfer
            ? '${entry.accountName} → ${entry.transferAccountName ?? ''}'
            : entry.accountName);
  }

  String _subtitle(BuildContext context, Transaction transaction) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale).format(transaction.date);
    return '${entry.accountName} · $date';
  }

}

/// The 44x44 category circle at the start of a recent-activity row.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({required this.entry, super.key});

  final TransactionWithDetails entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTransfer = entry.transaction.isTransfer;
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : CategoryAppearance.iconFor(entry.categoryIcon);
    final foreground = isTransfer
        ? colors.textSecondary
        : CategoryAppearance.colorFor(colors, entry.categoryColor);
    final background = isTransfer
        ? colors.muted
        : CategoryAppearance.softColorFor(colors, entry.categoryColor);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}
