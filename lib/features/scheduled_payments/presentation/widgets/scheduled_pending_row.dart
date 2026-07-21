import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../utils/scheduled_payment_format.dart';
import 'scheduled_category_icon_wrap.dart';
import 'scheduled_pending_count_chip.dart';

/// `Scheduled Pending Row/B2 — Compacta` (`QhuIP`): one row of "Por
/// confirmar" (HU-03/HU-04). Category icon tile + name (with the "×N" chip
/// when the template has more than one occurrence accumulated) over a
/// "Cuenta · Categoría" sub-line, the amount and its due date stacked on the
/// right, and a trailing `chevron-right`.
///
/// Fixed 52px height so the list scrolls predictably; both texts truncate to
/// a single line with an ellipsis instead of wrapping, which is what keeps
/// that height with real account names. The date lives in the right column,
/// under the amount, so the sub-line never competes for width with it — see
/// "Cadena de dependencia del alto" in the page spec.
class ScheduledPendingRow extends StatelessWidget {
  const ScheduledPendingRow({
    required this.entry,
    required this.onTap,
    this.count = 1,
    super.key,
  });

  final PendingScheduledOccurrence entry;
  final VoidCallback onTap;

  /// How many pending occurrences of this template the row stands for.
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final payment = entry.scheduledPayment;
    final isTransfer = payment.isTransfer;
    final name = ScheduledPaymentFormat.templateName(
      note: payment.note,
      categoryName: entry.categoryName,
      isTransfer: isTransfer,
      accountName: entry.accountName,
      transferAccountName: entry.transferAccountName,
    );
    final subtitle = ScheduledPaymentFormat.accountCategoryLine(
      accountName: entry.accountName,
      categoryName: entry.categoryName,
      isTransfer: isTransfer,
      transferAccountName: entry.transferAccountName,
    );

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            ScheduledCategoryIconWrap(
              isTransfer: isTransfer,
              categoryIcon: entry.categoryIcon,
              categoryColor: entry.categoryColor,
              cornerRadius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (count > 1) ...[
                        const SizedBox(width: 6),
                        ScheduledPendingCountChip(count: count),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amountLabel(payment),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    color: ScheduledPaymentFormat.amountColor(
                      colors,
                      payment.type,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ScheduledPaymentFormat.dateLabel(
                    context,
                    entry.occurrence.effectiveDate,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _amountLabel(ScheduledPayment payment) {
    final formatted = const MoneyFormatter()
        .formatSymbol(payment.amountMinor, currencyCode: payment.currency);
    return switch (payment.type) {
      // Signed like the movements list: `+` income, `-` expense; a transfer
      // is neither, so it stays neutral.
      ScheduledPaymentType.income => '+$formatted',
      ScheduledPaymentType.expense => '-$formatted',
      ScheduledPaymentType.transfer => formatted,
    };
  }
}
