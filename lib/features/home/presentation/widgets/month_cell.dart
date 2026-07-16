import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// One month cell of the month picker (HU-04): selected (filled `primary`),
/// normal, or future/disabled (dimmed, not tappable).
class MonthCell extends StatelessWidget {
  const MonthCell({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    super.key,
  });

  /// Already localized short month name (e.g. "jul").
  final String label;

  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      enabled: !isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1,
        child: Material(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colors.onPrimary : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
