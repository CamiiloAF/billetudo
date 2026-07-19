import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;

/// One row of the detail page's expandable history (criterion 13).
class ScheduledPaymentHistoryRow extends StatelessWidget {
  const ScheduledPaymentHistoryRow({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final tx.Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(LucideIcons.receipt, size: 18, color: colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat.yMMMd(locale).format(transaction.date),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                const MoneyFormatter().format(
                  transaction.amountMinor,
                  currencyCode: transaction.currency,
                ),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
