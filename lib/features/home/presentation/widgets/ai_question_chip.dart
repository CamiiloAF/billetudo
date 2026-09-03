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
    this.maxWidth,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDirectNav;

  /// Caps the chip's total width so a long label wraps to a 2nd line
  /// instead of growing indefinitely wide (issue #22's "regla de altura
  /// dinámica por fila" — `design-system/billetudo/pages/inicio.md`).
  ///
  /// When set, the label sizes off this constant directly instead of a
  /// `LayoutBuilder` reading the incoming constraints. That matters because
  /// `AiCardChips` shares one row height across its 4 chips with
  /// `IntrinsicHeight`, which queries each child's intrinsic height — a
  /// query `LayoutBuilder` cannot answer (Flutter throws
  /// `UnimplementedError` at layout time if one sits in that subtree).
  ///
  /// When null (e.g. the "Continuar" chip sharing a `Row` with the "Ahora
  /// no" `TextButton` in `ai_card_insight.dart`, where the available width
  /// can be under this chip's own preferred width on a real phone), the
  /// chip falls back to `LayoutBuilder` and shrinks to whatever room its
  /// parent actually gives it.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    const horizontalPadding = 14.0 * 2;
    const iconWidth = 16.0;
    const labelIconGap = 8.0;
    const reservedWidth = horizontalPadding + iconWidth + labelIconGap;

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    final icon = Icon(
      isDirectNav ? LucideIcons.arrowRight : LucideIcons.arrowUpRight,
      size: 16,
      color: colors.primaryOnSoft,
    );

    final fixedMaxWidth = maxWidth;

    return Material(
      color: colors.mutedStrong,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: fixedMaxWidth != null
            ? Container(
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: fixedMaxWidth - reservedWidth,
                      ),
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                    const SizedBox(width: labelIconGap),
                    icon,
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final labelMaxWidth = constraints.hasBoundedWidth
                      ? constraints.maxWidth - reservedWidth
                      : double.infinity;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: labelMaxWidth),
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle,
                          ),
                        ),
                        const SizedBox(width: labelIconGap),
                        icon,
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
