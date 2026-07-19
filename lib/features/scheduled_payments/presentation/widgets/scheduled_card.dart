import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_summary.dart';
import '../utils/scheduled_payment_format.dart';
import 'scheduled_category_icon_wrap.dart';

/// `Scheduled Card`: one row of the "próximos vencimientos" list (HU-04).
///
/// Shows the amount, account and category (criterion 11), the next due date,
/// and a "×N" chip when the template currently has more than one pending
/// occurrence accumulated (criterion 11/5) instead of repeating the row. A
/// second row carries the frequency chip ("cada mes"/"pago único") and the
/// "en N días" countdown pill.
class ScheduledCard extends StatelessWidget {
  const ScheduledCard({required this.entry, required this.onTap, super.key});

  final ScheduledPaymentSummary entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final payment = entry.scheduledPayment;
    final isTransfer = payment.isTransfer;
    final title = ScheduledPaymentFormat.templateTitle(
      categoryName: entry.categoryName,
      isTransfer: isTransfer,
      accountName: entry.accountName,
      transferAccountName: entry.transferAccountName,
    );

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScheduledCategoryIconWrap(
                isTransfer: isTransfer,
                categoryIcon: entry.categoryIcon,
                categoryColor: entry.categoryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (entry.hasPendingOccurrence) ...[
                          const SizedBox(width: 6),
                          ScheduledPendingCountChip(
                            count: entry.pendingOccurrenceCount,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.accountName} · ${ScheduledPaymentFormat.dateLabel(context, payment.nextDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: ScheduledFrequencyChip(
                            frequency: payment.frequency,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ScheduledDueInChip(nextDate: payment.nextDate),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _amountLabel(l10n, payment),
                style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }

  String _amountLabel(AppLocalizations l10n, ScheduledPayment payment) {
    final formatted = const MoneyFormatter()
        .format(payment.amountMinor, currencyCode: payment.currency);
    return switch (payment.type) {
      ScheduledPaymentType.income => '+$formatted',
      ScheduledPaymentType.expense => '-$formatted',
      ScheduledPaymentType.transfer => formatted,
    };
  }
}

/// The "×N" pill (criterion 11): a template appears once even when several
/// occurrences vencieron while the app was closed. Neutral tone on purpose —
/// this is a count, not an alert.
class ScheduledPendingCountChip extends StatelessWidget {
  const ScheduledPendingCountChip({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '×$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The frequency chip: a loop icon + "cada mes" for a repeating template, a
/// calendar icon + "Pago único" for a `once` one.
class ScheduledFrequencyChip extends StatelessWidget {
  const ScheduledFrequencyChip({required this.frequency, super.key});

  final ScheduledPaymentFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ScheduledPaymentFormat.frequencyIcon(frequency),
            size: 12,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              ScheduledPaymentFormat.frequencyLabel(l10n, frequency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "en N días" countdown pill next to the frequency chip.
class ScheduledDueInChip extends StatelessWidget {
  const ScheduledDueInChip({required this.nextDate, super.key});

  final DateTime nextDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ScheduledPaymentFormat.dueInLabel(
          l10n,
          nextDate,
          today: DateTime.now(),
        ),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primaryOnSoftStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
