import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The gradient "orb" avatar for the AI card (`design-system/billetudo/pages
/// /inicio.md` § "Card de IA — chrome condicional"): a 42×42 circle with the
/// brand gradient and a sparkles glyph, shared by the "con chips" and
/// insight variants of `AiCard`.
class AiOrb extends StatelessWidget {
  const AiOrb({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryDeep],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(LucideIcons.sparkles, size: 20, color: colors.onPrimary),
    );
  }
}
