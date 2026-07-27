import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/category_appearance.dart';

/// The `Icon Tile` component (60x60): one cell of the icon grid in the
/// icon/color picker (`lAxmS`).
///
/// Only the **selected** tile takes color (fill `$<color>-soft` + stroke
/// `$<color>` 2px + icon `$<color>`, where `<color>` is whatever the color grid
/// below currently has picked); the rest stay neutral
/// (`$muted`/`$text-secondary`).
///
/// When there is no color grid ([selectedColorToken] null, e.g. the budget
/// picker `XsnnD`), the selected treatment falls back to the brand family
/// (`$primary-soft` + `$primary` + `$primary-on-soft`) instead of the neutral
/// one — otherwise "selected" would be indistinguishable from "not selected".
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
    final neutralSelection = selectedColorToken == null;
    final Color fg;
    final Color bg;
    final Color stroke;
    if (!selected) {
      fg = colors.textSecondary;
      bg = colors.muted;
      stroke = Colors.transparent;
    } else if (neutralSelection) {
      fg = colors.primaryOnSoft;
      bg = colors.primarySoft;
      stroke = colors.primary;
    } else {
      fg = CategoryAppearance.colorFor(colors, selectedColorToken);
      bg = CategoryAppearance.softColorFor(colors, selectedColorToken);
      stroke = fg;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: iconName,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: stroke, width: 2),
          ),
          child:
              Icon(CategoryAppearance.iconFor(iconName), size: 24, color: fg),
        ),
      ),
    );
  }
}
