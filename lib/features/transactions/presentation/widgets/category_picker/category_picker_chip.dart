import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../categories/presentation/utils/category_appearance.dart';

/// One tile of the `Category Quick Picker` (`EIoVx`)/`mK8oI`: a 52x52 rounded
/// icon wrap above a centered label, toggling between the neutral and
/// selected fill/border/text scheme. The icon always keeps the category's
/// own decorative color — only the wrap's fill/border and the label react to
/// [selected]. Shared by Transacciones and Pagos Programados, the only two
/// screens that render the picker's quick chips.
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
    final iconColor = CategoryAppearance.colorFor(colors, category.color);
    final wrapColor = selected
        ? CategoryAppearance.softColorFor(colors, category.color)
        : colors.muted;
    final wrapBorder = selected ? Border.all(color: iconColor, width: 2) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: wrapColor,
                borderRadius: BorderRadius.circular(16),
                border: wrapBorder,
              ),
              child: Icon(
                CategoryAppearance.iconFor(category.icon),
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
