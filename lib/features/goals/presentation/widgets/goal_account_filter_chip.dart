import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// HU-12's "lista filtrada por cuenta" chip (`qFX42`'s "Filter Bar"): a
/// dismissible `$primary-soft` pill naming the account the list is scoped
/// to, closed via the `X`.
class GoalAccountFilterChip extends StatelessWidget {
  const GoalAccountFilterChip({
    required this.accountName,
    required this.onClear,
    super.key,
  });

  final String accountName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      child: Row(
        children: [
          Icon(LucideIcons.wallet, size: 16, color: colors.primaryOnSoftStrong),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.goalAccountFilterLabel(accountName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: l10n.goalAccountFilterClearTooltip,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
