import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import 'scheduled_category_icon_wrap.dart';
import 'scheduled_pending_row.dart';

/// The "Pendientes" section on top of the "próximos vencimientos" list
/// (HU-04): a "Por confirmar N" header (with its "aún no afectan tu saldo"
/// caption and the "Revisar todas" link) above a `$primary`-bordered card
/// showing up to [maxVisibleRows] pending occurrences, with an overflow row
/// when there are more.
///
/// Only rendered by the caller when [items] is not empty.
class ScheduledPendingCard extends StatelessWidget {
  const ScheduledPendingCard({
    required this.items,
    required this.onTapRow,
    required this.onReviewAll,
    this.maxVisibleRows = 4,
    super.key,
  });

  final List<PendingScheduledOccurrence> items;
  final ValueChanged<PendingScheduledOccurrence> onTapRow;
  final VoidCallback onReviewAll;
  final int maxVisibleRows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final visible = items.take(maxVisibleRows).toList();
    final overflow = items.skip(visible.length).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.scheduledPendingCardTitle(items.length),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.scheduledPendingCardCaption,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onReviewAll,
              icon: const Icon(LucideIcons.listChecks, size: 16),
              label: Text(l10n.scheduledReviewAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: colors.primary, width: 1.5),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in visible) ...[
                ScheduledPendingRow(entry: entry, onTap: () => onTapRow(entry)),
                const SizedBox(height: 6),
              ],
              if (overflow.isNotEmpty)
                ScheduledPendingOverflowRow(
                  overflow: overflow,
                  onTap: onReviewAll,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The overflow row ("Ver los otros N pendientes"): a strip of mini
/// category icon-wraps for the occurrences it represents, followed by the
/// count text and a trailing `chevron-right` — tapping it opens the same
/// full "Por confirmar" list as "Revisar todas".
class ScheduledPendingOverflowRow extends StatelessWidget {
  const ScheduledPendingOverflowRow({
    required this.overflow,
    required this.onTap,
    super.key,
  });

  final List<PendingScheduledOccurrence> overflow;
  final VoidCallback onTap;

  static const int _maxIcons = 3;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            for (final entry in overflow.take(_maxIcons)) ...[
              ScheduledCategoryIconWrap(
                isTransfer: entry.scheduledPayment.isTransfer,
                categoryIcon: entry.categoryIcon,
                categoryColor: entry.categoryColor,
                size: _iconSize,
                iconSize: 11,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                l10n.scheduledPendingCardOverflow(overflow.length),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
