import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One option of the alert-threshold sheet (`m3jomu/QvYfP`): a `[13, 4]` row
/// with a 15pt label (700 when picked, 500 otherwise), an optional 12/500
/// subtitle and a trailing affordance — a `$primary` check for the value
/// options, a `$text-secondary` chevron for the one that opens another sheet.
class BudgetThresholdOption extends StatelessWidget {
  const BudgetThresholdOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing = BudgetThresholdTrailing.check,
    super.key,
  });

  /// Already localized.
  final String label;

  /// Already localized. `null` renders a single-line row.
  final String? subtitle;

  final bool selected;
  final BudgetThresholdTrailing trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            switch (trailing) {
              BudgetThresholdTrailing.chevron => Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.textSecondary,
                ),
              BudgetThresholdTrailing.check when selected => Icon(
                  LucideIcons.check,
                  size: 20,
                  color: colors.primary,
                ),
              BudgetThresholdTrailing.check => const SizedBox(width: 20),
            },
          ],
        ),
      ),
    );
  }
}

/// What an option shows on its right edge.
enum BudgetThresholdTrailing {
  /// A check, visible only while the option is the picked one.
  check,

  /// A chevron: the option opens another sheet instead of picking a value.
  chevron,
}
