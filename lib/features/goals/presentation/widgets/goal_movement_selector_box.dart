import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Tappable, dropdown-styled box for the fecha field in
/// `GoalContributionSheet` and `EditGoalMovementSheet`.
class GoalMovementSelectorBox extends StatelessWidget {
  const GoalMovementSelectorBox({
    required this.icon,
    required this.value,
    required this.onTap,
    this.trailingIcon = LucideIcons.chevronDown,
    super.key,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  /// Pencil's `wOlOA` (Form Field) default trailing icon is chevron-down,
  /// but `EditGoalMovementSheet`'s Fecha instance (`vvxXn`/`REkBO`'s
  /// `PrXDA`) overrides it to chevron-right — matched by passing
  /// `LucideIcons.chevronRight` from that caller.
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(trailingIcon, color: colors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
