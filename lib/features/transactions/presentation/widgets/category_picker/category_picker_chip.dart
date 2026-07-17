import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';

/// One chip of the `Category Quick Picker` (`EIoVx`): a category's icon + name,
/// styled as a selectable pill. Selected reuses the app's selectable-row
/// pattern (`$primary-soft` fill, `$primary` border, `primary-on-soft-strong`
/// content); unselected is the neutral `$surface`/`$border` chip with the
/// category's own decorative color for its icon.
class CategoryPickerChip extends StatelessWidget {
  const CategoryPickerChip({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground =
        selected ? colors.primaryOnSoftStrong : colors.textSecondary;
    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryAppearance.iconFor(category.icon),
                size: 16,
                color: selected
                    ? colors.primaryOnSoftStrong
                    : CategoryAppearance.colorFor(colors, category.color),
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
