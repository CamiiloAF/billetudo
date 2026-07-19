import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../utils/scheduled_payment_format.dart';
import 'scheduled_card.dart' show ScheduledDueInChip;
import 'scheduled_category_icon_wrap.dart';
import 'scheduled_payment_detail_badge.dart';

/// The detail's "Identity Strip": the category icon-wrap, the template's
/// display name and a "categoría · tipo" subtitle — sits directly above the
/// Hero Card as its own row instead of the plain title text the header used
/// to show.
class ScheduledPaymentIdentityStrip extends StatelessWidget {
  const ScheduledPaymentIdentityStrip({
    required this.payment,
    required this.accountName,
    this.transferAccountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    super.key,
  });

  final ScheduledPayment payment;
  final String accountName;
  final String? transferAccountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final isTransfer = payment.isTransfer;
    final title = ScheduledPaymentFormat.templateTitle(
      categoryName: categoryName,
      isTransfer: isTransfer,
      accountName: accountName,
      transferAccountName: transferAccountName,
    );
    final subtitleParts = [
      if (categoryName != null && categoryName!.isNotEmpty) categoryName!,
      _typeLabel(l10n, payment.type),
    ];

    return Row(
      children: [
        ScheduledCategoryIconWrap(
          isTransfer: isTransfer,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _typeLabel(AppLocalizations l10n, ScheduledPaymentType type) =>
      switch (type) {
        ScheduledPaymentType.income => l10n.transactionTypeIncome,
        ScheduledPaymentType.expense => l10n.transactionTypeExpense,
        ScheduledPaymentType.transfer => l10n.transactionTypeTransfer,
      };
}

/// The detail's "Hero Híbrido" (`OY2Kj`/`Eyold`/`XmaSX`): a neutral card with
/// the "PRÓXIMO PAGO" caption, the amount next to the due-in pill (or the
/// "Pendiente de confirmar" badge when a manual occurrence is waiting), and a
/// plain-language sentence describing the template's recurrence — the single
/// place the amount is shown on the detail screen.
///
/// Tappable only when [pending] is not null: same "tap to confirm" affordance
/// the previous single-line "Próximo pago" text already offered.
class ScheduledPaymentHeroCard extends StatelessWidget {
  const ScheduledPaymentHeroCard({
    required this.payment,
    required this.pending,
    required this.onTapPending,
    super.key,
  });

  final ScheduledPayment payment;
  final PendingScheduledOccurrence? pending;
  final VoidCallback onTapPending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final isPending = pending != null;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: isPending ? onTapPending : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scheduledPaymentDetailHeroLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _amountLabel(payment),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: ScheduledPaymentFormat.amountColor(
                        colors,
                        payment.type,
                      ),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isPending)
                    ScheduledPaymentDetailBadge(
                        label: l10n.scheduledPendingBadge)
                  else
                    ScheduledDueInChip(nextDate: payment.nextDate),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ScheduledPaymentFormat.recurrencePhrase(context, l10n, payment),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _amountLabel(ScheduledPayment payment) {
    final formatted = const MoneyFormatter()
        .formatSymbol(payment.amountMinor, currencyCode: payment.currency);
    return switch (payment.type) {
      ScheduledPaymentType.income => '+$formatted',
      ScheduledPaymentType.expense => '-$formatted',
      ScheduledPaymentType.transfer => formatted,
    };
  }
}
