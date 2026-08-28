import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// `AI Question Chip` (`tMqvn`): one suggested question in the AI card's
/// horizontal scroll row (`design-system/billetudo/pages/inicio.md` § "Card
/// de IA").
///
/// [isDirectNav] distinguishes the one chip that never opens the chat
/// ("Ayúdame a presupuestar", which navigates straight to `onCreateBudget`)
/// from every other chip, which opens a conversation: the arrow points
/// straight (`arrow-right`) instead of diagonally (`arrow-up-right`), so the
/// user does not expect a chat where there is actually a direct navigation.
class AiQuestionChip extends StatelessWidget {
  const AiQuestionChip({
    required this.label,
    required this.onTap,
    this.isDirectNav = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDirectNav;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    // The chip is used both unconstrained (the horizontal scroll of
    // suggested questions, where it should size to its own 200px cap) and
    // constrained (the insight card's "Continuar" chip, sharing a Row with
    // the "Ahora no" TextButton — see `ai_card_insight.dart`'s `AiCardInsight`,
    // where the available width can be under 200px on a real phone). The
    // label's max width has to shrink to whatever room is actually left
    // instead of insisting on the full 200px and overflowing the Row.
    const horizontalPadding = 16.0 * 2;
    const iconWidth = 16.0;
    const labelIconGap = 8.0;
    const reservedWidth = horizontalPadding + iconWidth + labelIconGap;

    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxLabelWidth = constraints.hasBoundedWidth
                ? (constraints.maxWidth - reservedWidth).clamp(0.0, 200.0)
                : 200.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: labelIconGap),
                  Icon(
                    isDirectNav
                        ? LucideIcons.arrowRight
                        : LucideIcons.arrowUpRight,
                    size: 16,
                    color: colors.primaryOnSoft,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
