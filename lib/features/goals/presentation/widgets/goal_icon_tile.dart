import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/goal_icon_appearance.dart';

/// One 60x60 cell of the "Elegir ícono" grid (`cwj6B`'s `skuz9` Icon Tile
/// instances): a circle that stays neutral (`$muted`/`$text-secondary`) until
/// picked, then wears the brand family (`$primary-soft`/`$primary`/
/// `$primary-on-soft`) — Metas never colors a goal by its own token (HU-01),
/// so there is no per-color grid to fall back to, unlike Categorías' own
/// `IconTile`.
class GoalIconTile extends StatelessWidget {
  const GoalIconTile({
    required this.iconName,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String iconName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.primaryOnSoft : colors.textSecondary;
    final bg = selected ? colors.primarySoft : colors.muted;
    final stroke = selected ? colors.primary : Colors.transparent;

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
          child: Icon(GoalIconAppearance.iconFor(iconName), size: 24, color: fg),
        ),
      ),
    );
  }
}
