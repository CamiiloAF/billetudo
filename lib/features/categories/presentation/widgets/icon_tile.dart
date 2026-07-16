import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/category_appearance.dart';

/// The `Icon Tile` component (60x60): one cell of the icon grid in the
/// icon/color picker (`lAxmS`).
///
/// Only the **selected** tile takes color (fill `$<color>-soft` + stroke
/// `$<color>` + icon `$<color>`, where `<color>` is whatever the color grid
/// below currently has picked); the rest stay neutral
/// (`$muted`/`$text-secondary`).
class IconTile extends StatelessWidget {
  const IconTile({
    required this.iconName,
    required this.selected,
    required this.selectedColorToken,
    required this.onTap,
    super.key,
  });

  final String iconName;
  final bool selected;

  /// The color currently picked in the color grid — resolves this tile's
  /// selected treatment, so both grids always agree (`categorias.md`).
  final String? selectedColorToken;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected
        ? CategoryAppearance.colorFor(colors, selectedColorToken)
        : colors.textSecondary;
    final bg = selected
        ? CategoryAppearance.softColorFor(colors, selectedColorToken)
        : colors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: iconName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: fg, width: 1.5) : null,
          ),
          child: Icon(CategoryAppearance.iconFor(iconName), color: fg),
        ),
      ),
    );
  }
}
