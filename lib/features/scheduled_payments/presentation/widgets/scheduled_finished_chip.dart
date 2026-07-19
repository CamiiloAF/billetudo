import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// "Terminada": the chip a finished template shows where an active one shows
/// its cadence ("cada mes").
///
/// The slot is never left empty: active and finished cards now live in the
/// same screen, and the absence of a chip is not something the eye catches
/// without comparing two cards side by side. Neutral `$muted` /
/// `$text-secondary` — a finished template is history, not an error, and it is
/// never dimmed either (that would read as disabled, or as a reproach).
class ScheduledFinishedChip extends StatelessWidget {
  const ScheduledFinishedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
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
            LucideIcons.circleCheck,
            size: 12,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              AppLocalizations.of(context).scheduledFinishedCardChip,
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
