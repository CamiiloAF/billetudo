import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../utils/scheduled_payment_format.dart';
import 'scheduled_card.dart' show ScheduledDueInChip;
import 'scheduled_category_icon_wrap.dart';

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
    final title = ScheduledPaymentFormat.templateName(
      note: payment.note,
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

/// The detail's "Hero Híbrido" (`OY2Kj`/`Eyold`/`XmaSX`): a neutral card that
/// answers "cuándo cae el próximo pago y de cuánto" in Pencil's order —
/// eyebrow + "en N días" pill, the **big date**, the amount, and a
/// plain-language sentence (with `repeat`/`calendar-check`) describing the
/// template's recurrence. Single place the amount is shown on this screen.
///
/// [executed] flips it to `Eyold`: a `once` template whose transaction has
/// already been generated reads "PAGO EJECUTADO", drops the countdown pill
/// (nothing is coming) and keeps the past date.
///
/// Tappable only when [pending] is not null: same "tap to confirm" affordance
/// the previous single-line "Próximo pago" text already offered.
///
/// Also carries the "Confirmar ahora" CTA (`Ht24a` in `OY2Kj`,
/// `docs/bugfixes.md` point 1): a full-width strip pinned to the bottom of
/// the hero, below the recurrence phrase, shown only for an automatic-mode
/// template whose next date is not due yet. Once it is due, [pending]
/// becomes non-null and the whole hero is tappable instead — the CTA never
/// shows alongside that, it would be a redundant second affordance.
class ScheduledPaymentHeroCard extends StatelessWidget {
  const ScheduledPaymentHeroCard({
    required this.payment,
    required this.pending,
    required this.onTapPending,
    required this.onConfirmNow,
    this.executed = false,
    super.key,
  });

  final ScheduledPayment payment;
  final PendingScheduledOccurrence? pending;
  final VoidCallback onTapPending;

  /// Invoked by the "Confirmar ahora" CTA. Only rendered when
  /// [showConfirmNow] is true.
  final VoidCallback onConfirmNow;

  /// True for `Eyold`: the one-off already fired, so the hero is history.
  final bool executed;

  /// Automatic mode, not yet due (no [pending] materialized for it), still
  /// active and not deleted — the one case the due-date tap does not already
  /// cover.
  bool get showConfirmNow =>
      !executed &&
      !payment.isDeleted &&
      !payment.requiresConfirmation &&
      pending == null;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      executed
                          ? l10n.scheduledPaymentDetailHeroLabelExecuted
                          : l10n.scheduledPaymentDetailHeroLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (!executed) ScheduledDueInChip(nextDate: payment.nextDate),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ScheduledPaymentFormat.heroDateLabel(context, payment.nextDate),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _amountLabel(payment),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: ScheduledPaymentFormat.amountColor(
                    colors,
                    payment.type,
                  ),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ScheduledPaymentFormat.frequencyIcon(payment.frequency),
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ScheduledPaymentFormat.recurrencePhrase(
                          context, l10n, payment),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
              // No "pendiente de confirmar" badge here: the hero already
              // carries a `$primary-soft` pill (the countdown), and a second
              // pill of the same colour and weight in the same card would
              // read as the same affordance with a different meaning. The
              // pending state is expressed in the card's "Estado" row.
              if (showConfirmNow) ...[
                const SizedBox(height: 10),
                ScheduledPaymentConfirmNowButton(onTap: onConfirmNow),
              ],
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
      // Unsigned expense, per Pencil: only income carries a sign.
      ScheduledPaymentType.expense => formatted,
      ScheduledPaymentType.transfer => formatted,
    };
  }
}

/// "Confirmar ahora" (`Ht24a` in `OY2Kj`): full-width strip pinned to the
/// bottom of [ScheduledPaymentHeroCard], `zap` + label in
/// `$primary-on-soft-strong` over `$primary-soft`. `zap` was picked over
/// `check-circle`/`circle-check-big` (already "Terminada"/pago ejecutado in
/// this feature) and `calendar-check` (already "pago único"): it reads as
/// "ahora, sin esperar" instead of "completado".
class ScheduledPaymentConfirmNowButton extends StatelessWidget {
  const ScheduledPaymentConfirmNowButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.zap,
                size: 18,
                color: colors.primaryOnSoftStrong,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.scheduledPaymentDetailConfirmNowCta,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primaryOnSoftStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
