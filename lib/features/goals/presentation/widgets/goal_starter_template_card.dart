import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/goal_starter_templates.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';

/// HU-13's empty-state template row (`vjTZR` Goal Template Row): a one-tap
/// starter that pre-fills the create-goal form with [template]'s name/icon
/// and, when it has a data-derived suggestion, a suggested amount the user
/// can still edit.
class GoalStarterTemplateCard extends StatelessWidget {
  const GoalStarterTemplateCard({
    required this.template,
    required this.onTap,
    this.suggestedTargetMinor,
    this.currency = 'COP',
    super.key,
  });

  final GoalStarterTemplate template;
  final VoidCallback onTap;
  final int? suggestedTargetMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final suggested = suggestedTargetMinor;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  GoalIconAppearance.iconFor(template.icon),
                  size: 20,
                  color: colors.primaryOnSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (suggested != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈ ${GoalFormat.amount(suggested, currency)}',
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
              Icon(LucideIcons.plus, size: 18, color: colors.primaryOnSoft),
            ],
          ),
        ),
      ),
    );
  }
}
