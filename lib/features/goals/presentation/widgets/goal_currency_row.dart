import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// A single currency option in `GoalCurrencyPickerSheet`.
class GoalCurrencyRow extends StatelessWidget {
  const GoalCurrencyRow({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: selected ? colors.primary : colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Text(
                  code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.check, size: 18, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
