import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One option of the alert-threshold sheet (`m3jomu/QvYfP`): a `[13, 4]` row
/// with a 15pt label (700 when picked, 500 otherwise), an optional 12/500
/// subtitle and a trailing affordance: a `$primary` check whenever the option
/// is the picked one, plus a `$text-secondary` chevron on the option that
/// opens another sheet (the two coexist — the chevron says "this opens
/// something", the check says "this is the current value").
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

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
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
              // The check states "this is the picked one" for every option,
              // chevron ones included: on `Personalizado` the bold label was
              // the only cue, so the selection lived in font weight alone —
              // inconsistent with the rest of the sheet and unreadable for
              // anyone who cannot compare weights.
              if (selected)
                Icon(LucideIcons.check, size: 20, color: colors.primary)
              else if (trailing == BudgetThresholdTrailing.check)
                const SizedBox(width: 20),
              if (trailing == BudgetThresholdTrailing.chevron) ...[
                if (selected) const SizedBox(width: 6),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// What an option shows on its right edge.
enum BudgetThresholdTrailing {
  /// Nothing but the selection check.
  check,

  /// A chevron: the option opens another sheet instead of picking a value.
  chevron,
}
