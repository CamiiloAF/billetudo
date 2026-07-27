import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../utils/scheduled_payment_format.dart';

/// One "omitido" row of the detail's Historial (page spec, Pencil `GPlOy`): a
/// skipped occurrence that generated no transaction. The "omitido" signal is
/// deliberately redundant — `calendar-x` icon + neutral "Omitido" badge +
/// struck-through amount — and never uses `$expense`/red (tone rule: skipping
/// a payment is not a punishment).
///
/// Sits in the same surface card as the confirmed `ScheduledPaymentHistoryRow`
/// so the two row types read as one list.
class ScheduledSkippedHistoryRow extends StatelessWidget {
  const ScheduledSkippedHistoryRow({
    required this.name,
    required this.date,
    required this.amountMinor,
    required this.currency,
    required this.onRecover,
    super.key,
  });

  /// Already resolved by the caller with `ScheduledPaymentFormat.templateName`.
  final String name;

  /// The occurrence's effective date (`snoozedToDate ?? occurrenceDate`).
  final DateTime date;

  final int amountMinor;
  final String currency;
  final VoidCallback onRecover;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              // 36×36 / r14 / icon 18, symmetric with the confirmed row's
              // `ScheduledCategoryIconWrap` so both history rows share a height.
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                LucideIcons.calendarX,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.scheduledSkippedBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          ScheduledPaymentFormat.dateLabel(context, date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  const MoneyFormatter().formatSymbol(
                    amountMinor,
                    currencyCode: currency,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    // Pencil does not serialize strikethrough (a known
                    // limitation, like ellipsis), so it looks flat in the
                    // .pen/goldens — Flutter renders it. Page spec: do not omit.
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                // The link's own text is ~15px tall; the padding grows the tap
                // target toward 44pt (page spec: the mock's ~15px link does not
                // reach it, known debt — same fix as `Tag Chip`).
                InkWell(
                  onTap: onRecover,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 11,
                    ),
                    child: Text(
                      l10n.scheduledRecoverAction,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primaryOnSoftStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
