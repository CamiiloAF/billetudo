import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The "destacado en Inicio" badge (`sEyU6`): a 22px `$primary` circle,
/// stroked 2px in `$background` (so it separates from the page behind the
/// card, not the card's own border), with a 12px `star` in `$on-primary`.
///
/// Overlaps the top-right corner of `BudgetLine`, same "negative Positioned
/// + `Clip.none`" pattern as `BudgetIconButton`'s edit badge.
class BudgetFeaturedBadge extends StatelessWidget {
  const BudgetFeaturedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.background, width: 2),
      ),
      child: Icon(
        LucideIcons.star,
        size: 12,
        color: colors.onPrimary,
      ),
    );
  }
}
