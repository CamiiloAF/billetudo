import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The "🔔 Te avisamos" chip of a `Scheduled Card`: only rendered for a
/// manual-mode template (`requiresConfirmation`), where reaching the due date
/// creates a pending occurrence instead of touching the balance (HU-03).
class ScheduledManualModeChip extends StatelessWidget {
  const ScheduledManualModeChip({super.key});

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
          Icon(LucideIcons.bell, size: 12, color: colors.primaryOnSoftStrong),
          const SizedBox(width: 4),
          // Flexible so the label ellipsizes within a tight parent instead of
          // overflowing: `overflow: ellipsis` alone does nothing while the Row
          // is `MainAxisSize.min` and hands the text its full natural width.
          Flexible(
            child: Text(
              l10n.scheduledManualNotifyChip,
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
