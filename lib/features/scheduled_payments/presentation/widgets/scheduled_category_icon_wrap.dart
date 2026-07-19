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
    this.cornerRadius,
    this.background,
    this.foreground,
    super.key,
  });

  final bool isTransfer;
  final String? categoryIcon;
  final String? categoryColor;
  final double size;
  final double iconSize;

  /// Squircle radius of the tile. Defaults to a circle (`size / 2`); the
  /// "por confirmar" row overrides it to 14 (design spec, node `QhuIP`).
  final double? cornerRadius;

  /// Overrides of the tile's own palette, for the surfaces whose design
  /// colours the tile by the *movement* instead of by the category — the
  /// confirmation sheet's `income` head (`EJAvD`), tinted `income-soft`.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedForeground = foreground ??
        (isTransfer
            ? colors.textSecondary
            : CategoryAppearance.colorFor(colors, categoryColor));
    final resolvedBackground = background ??
        (isTransfer
            ? colors.muted
            : CategoryAppearance.softColorFor(colors, categoryColor));
    final icon = isTransfer
        ? LucideIcons.arrowLeftRight
        : CategoryAppearance.iconFor(categoryIcon);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(cornerRadius ?? size / 2),
      ),
      child: Icon(icon, color: resolvedForeground, size: iconSize),
    );
  }
}
