import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../utils/category_appearance.dart';

/// One indented subcategory row inside an expanded `CategoryAccordionRow`.
class CategorySubrow extends StatelessWidget {
  const CategorySubrow({required this.category, this.onTap, super.key});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(left: 44, top: 8, bottom: 8, right: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CategoryAppearance.softColorFor(colors, category.color),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                CategoryAppearance.iconFor(category.icon),
                size: 16,
                color: CategoryAppearance.colorFor(colors, category.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
