import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// One month cell of `MonthPickerSheet` (`Month Cell`, `DB3bz`): selected
/// (filled `$primary`), normal, or future/disabled (dimmed, not tappable —
/// the app has no data yet for a month that has not happened).
class MonthCell extends StatelessWidget {
  const MonthCell({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    super.key,
  });

  /// Already localized short month name (e.g. "Ene").
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
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: isSelected
                      ? colors.onPrimary
                      : isDisabled
                          ? colors.textSecondary
                          : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
