import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `Quick Access Chip A · Con badge` (`njGBt`): the "Pagos programados" chip
/// with a pending-occurrence counter to the right of its label
/// (`design-system/billetudo/pages/inicio.md` § "Acceso rápido").
///
/// Built as its own component rather than a slot on the base chip
/// (`QuickAccessChip`/`HAPxy`), which already has dozens of instances with
/// overrides — MASTER's rule against restructuring an already-instanced
/// reusable. [count] counts only occurrences pending confirmation, caps the
/// label at "9+" above 9, and the caller never renders this widget at all
/// for a zero count (it falls back to the plain `QuickAccessChip` instead —
/// never a badge showing zero).
class QuickAccessChipWithBadge extends StatelessWidget {
  const QuickAccessChipWithBadge({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;

  /// Always > 0 — the caller renders the plain chip instead for a zero
  /// count.
  final int count;
  final VoidCallback onTap;

  String get _badgeLabel => count > 9 ? '9+' : '$count';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _badgeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
