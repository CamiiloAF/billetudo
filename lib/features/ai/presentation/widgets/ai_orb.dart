import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The assistant's avatar (`billetudo.pen` `Orb`, e.g. `m7HAd`): a 30x30
/// angular `$primary` → `$primary-deep` → `$primary` gradient circle with a
/// `sparkles` glyph, repeated next to every assistant bubble — the "chat with
/// brand presence" identity `asistente-ia.md` names as the screen's north
/// star.
class AiOrb extends StatelessWidget {
  const AiOrb({this.size = 30, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [colors.primary, colors.primaryDeep, colors.primary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.sparkles,
        size: size * 0.47,
        color: colors.onPrimary,
      ),
    );
  }
}
