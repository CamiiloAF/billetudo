import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../utils/scheduled_payment_format.dart';

/// `Scheduled Pending Row`: one row of "Por confirmar" (HU-03/HU-04).
///
/// Fixed 52px height so the list scrolls predictably; the title truncates to
/// a single line with an ellipsis instead of wrapping, to keep that height —
/// deliberate trade-off for long account/category names, documented in the
/// design spec.
class ScheduledPendingRow extends StatelessWidget {
  const ScheduledPendingRow(
      {required this.entry, required this.onTap, super.key});

  final PendingScheduledOccurrence entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final payment = entry.scheduledPayment;
    final title = entry.categoryName ??
        (payment.isTransfer
            ? '${entry.accountName} → ${entry.transferAccountName ?? ''}'
            : entry.accountName);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _dateLabel(context),
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
                  _amountLabel(l10n, payment),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ScheduledPaymentFormat.amountColor(
                      colors,
                      payment.type,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _amountLabel(AppLocalizations l10n, ScheduledPayment payment) {
    final formatted = const MoneyFormatter()
        .formatSymbol(payment.amountMinor, currencyCode: payment.currency);
    return switch (payment.type) {
      ScheduledPaymentType.income => '+$formatted',
      ScheduledPaymentType.expense => '-$formatted',
      ScheduledPaymentType.transfer => formatted,
    };
  }

  String _dateLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(entry.occurrence.effectiveDate);
  }
}
