import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// A single tappable chip in `GoalQuickAmountRow` (a fixed quick amount, a
/// custom one, or the "Otro monto" fallback). None of them carry a leading
/// icon in the current design (`Qi3aR`'s `j1K3L`); [icon] is kept generic
/// in case a future variant needs one.
///
/// [onRemove] adds the inline "x" (`Owsx0`/`FXTgn`, mirroring `Tag Chip`
/// `nM9ea` in Transacciones) that only custom chips carry — tapping it fires
/// [onRemove] instead of [onTap], as its own tap target, so the label keeps
/// opening the sheet even on a removable chip.
class QuickAmountChip extends StatelessWidget {
  const QuickAmountChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.onRemove,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: colors.primaryOnSoftStrong,
    );
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon case final icon?) ...[
                    Icon(icon, size: 15, color: colors.primaryOnSoftStrong),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove case final onRemove?) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
