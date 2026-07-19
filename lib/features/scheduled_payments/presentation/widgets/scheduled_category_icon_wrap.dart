import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/utils/category_appearance.dart';

/// The category "icon-wrap" a template uses across the feature: a
/// transfer icon on a neutral background for `transfer` templates, or the
/// category's own icon/color (`CategoryAppearance`) otherwise.
///
/// Extracted from `ScheduledCard` so the confirmation sheet's head renders
/// the exact same icon/color mechanism instead of re-deriving it.
class ScheduledCategoryIconWrap extends StatelessWidget {
  const ScheduledCategoryIconWrap({
    required this.isTransfer,
    this.categoryIcon,
    this.categoryColor,
    this.size = 44,
    this.iconSize = 20,
    super.key,
  });

  final bool isTransfer;
  final String? categoryIcon;
  final String? categoryColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isTransfer
        ? colors.textSecondary
        : CategoryAppearance.colorFor(colors, categoryColor);
    final background = isTransfer
        ? colors.muted
        : CategoryAppearance.softColorFor(colors, categoryColor);
    final icon =
        isTransfer ? LucideIcons.arrowLeftRight : CategoryAppearance.iconFor(categoryIcon);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(icon, color: foreground, size: iconSize),
    );
  }
}
