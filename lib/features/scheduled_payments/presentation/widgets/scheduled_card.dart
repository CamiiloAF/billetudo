import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_summary.dart';
import '../utils/scheduled_payment_format.dart';
import 'scheduled_category_icon_wrap.dart';
import 'scheduled_finished_chip.dart';
import 'scheduled_manual_mode_chip.dart';

/// `tit0W` geometry: 18 of corner radius, 14 of padding and 12 between the two
/// axes — the card is slightly tighter and rounder than the generic
/// generic card, and it carries a 1px `$border` stroke.
const double _cardRadius = 18;
const double _cardPadding = 14;
const double _cardGap = 12;

/// `Scheduled Card`: one row of the "próximos vencimientos" list (HU-04).
///
/// Shows the amount, account and category (criterion 11), the next due date,
/// and a "×N" chip when the template currently has more than one pending
/// occurrence accumulated (criterion 11/5) instead of repeating the row. A
/// second row carries the frequency chip ("cada mes"/"pago único") and the
/// "en N días" countdown pill.
class ScheduledCard extends StatelessWidget {
  const ScheduledCard({
    required this.entry,
    required this.onTap,
    this.isFinished = false,
    super.key,
  });

  final ScheduledPaymentSummary entry;
  final VoidCallback onTap;

  /// True inside the "Terminados" filter. Same geometry as an active card
  /// (amount on top, full-card tap target, no dimming): these are navigable
  /// history, not disabled rows. Only the bottom axis changes — the cadence
  /// chip becomes "Terminada" and the countdown becomes "Último pago · fecha".
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final payment = entry.scheduledPayment;
    final isTransfer = payment.isTransfer;
    final title = ScheduledPaymentFormat.templateName(
      note: payment.note,
      categoryName: entry.categoryName,
      isTransfer: isTransfer,
      accountName: entry.accountName,
      transferAccountName: entry.transferAccountName,
    );

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ScheduledPaymentFormat.accountCategoryLine(
                            accountName: entry.accountName,
                            categoryName: entry.categoryName,
                            isTransfer: isTransfer,
                            transferAccountName: entry.transferAccountName,
                          ),
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
              // `tit0W/UwRRQ`: the bottom axis is a sibling of `Top` at card
              // level, not a third line of the text column. It spans the full
              // card width, so the chip starts under the avatar and the meta
              // ends at the card's padding edge. Active and finished cards
              // share it — only the chip and the trailing label change.
              const SizedBox(height: _cardGap),
              Row(
                children: [
                  // `a1vmQ` fills the row and `CyI5F` is `fit_content`, so the
                  // chips take the slack and the meta sits flush against the
                  // card's padding edge. Two `Flexible`s instead would split
                  // the free space in halves and leave the meta stranded mid
                  // card — the chip only needs its label's width, but its
                  // share is not given back.
                  Expanded(
                    child: Row(
                      children: [
                        if (isFinished)
                          const Flexible(child: ScheduledFinishedChip())
                        else
                          Flexible(
                            child: ScheduledFrequencyChip(
                              frequency: payment.frequency,
                            ),
                          ),
                        if (!isFinished && payment.requiresConfirmation) ...[
                          const SizedBox(width: 6),
                          const Flexible(child: ScheduledManualModeChip()),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFinished
                        ? _lastPaymentLabel(context, l10n)
                        : _dueLabel(context, l10n, payment),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "12 ago · en 3 días": the next due date and its countdown, plain text
  /// on the right of the chip row (page spec) — not a chip, so the only
  /// pill-shaped elements of the row are the frequency and the mode.
  String _dueLabel(
    BuildContext context,
    AppLocalizations l10n,
    ScheduledPayment payment,
  ) {
    final date = ScheduledPaymentFormat.dateLabel(context, payment.nextDate);
    final dueIn = ScheduledPaymentFormat.dueInLabel(
      l10n,
      payment.nextDate,
      today: DateTime.now(),
    );
    return '$date · $dueIn';
  }

  /// "Último pago · 15 mar 2026": the date of the last occurrence the template
  /// really generated, with an explicit year.
  ///
  /// Labeled on purpose — the same slot reads "en 3 días" on an active card,
  /// and for a repeating template that reached its `endDate` the last payment
  /// and the end date are different dates. Empty when the template stopped
  /// without ever firing: there is no payment to name.
  String _lastPaymentLabel(BuildContext context, AppLocalizations l10n) {
    final date = entry.lastPaymentDate;
    if (date == null) {
      return '';
    }
    return l10n.scheduledFinishedLastPayment(
      ScheduledPaymentFormat.shortDateLabel(context, date),
    );
  }

  String _amountLabel(AppLocalizations l10n, ScheduledPayment payment) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(12),
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
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ScheduledPaymentFormat.dueInLabel(
          l10n,
          nextDate,
          today: DateTime.now(),
        ),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primaryOnSoftStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
