import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../utils/category_appearance.dart';

/// The `Parent Category Row` component: icon-wrap + name + check on the
/// right when selected. Used by the parent picker (`Q55fEz`) and reused,
/// unfiltered, by the "Reasignar a otra categoría" pickers of HU-04.
class ParentCategoryRow extends StatelessWidget {
  const ParentCategoryRow({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CategoryAppearance.softColorFor(colors, category.color),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CategoryAppearance.iconFor(category.icon),
                size: 20,
                color: CategoryAppearance.colorFor(colors, category.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (selected) Icon(LucideIcons.check, color: colors.primaryOnSoft),
          ],
        ),
      ),
    );
  }
}
