import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Circular 44x44 icon-wrap button (`$muted` background) used to edit a
/// root category from `CategoryAccordionRow` (`R6fYf`, "Category Manage
/// Row" in Pencil).
class CategoryEditRootButton extends StatelessWidget {
  const CategoryEditRootButton({
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.muted,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              LucideIcons.pencil,
              size: 18,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
