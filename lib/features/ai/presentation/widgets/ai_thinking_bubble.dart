import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'ai_orb.dart';

/// The "pensando" bubble (`billetudo.pen` `M2oLsq`/`baSh8`): three neutral
/// dots instead of text, shown while a turn is in flight. No precedent for
/// "escribiendo…" existed anywhere in the app before this — a new pattern,
/// already approved in the design review.
class AiThinkingBubble extends StatelessWidget {
  const AiThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiOrb(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
