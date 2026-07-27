import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The "Deuda" badge (`Y5FQT`) appended to a `ScheduledCard`'s chip row when
/// the template is a debt's cuota (`scheduledPayment.debtId != null`, HU-03): a
/// subtle `$primary-soft` chip with a `landmark` icon and a
/// `$primary-on-soft-strong` label. Sutil, marca — nunca alarma.
class ScheduledDebtChip extends StatelessWidget {
  const ScheduledDebtChip({super.key});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.landmark,
            size: 12,
            color: colors.primaryOnSoftStrong,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.scheduledDebtChipLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primaryOnSoftStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
