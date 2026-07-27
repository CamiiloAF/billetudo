import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';

/// The `Menu Row` component (Pencil `hIbs3`): a circular `$muted` icon-wrap
/// (40pt, fully round), a 15/600 label and a trailing chevron — the row shape
/// of a `⋮` action sheet (e.g. Deudas' "Editar/Cerrar/Eliminar deuda",
/// `g57hEW`).
///
/// Distinct from `SheetActionRow` (rounded-square icon-wrap, no chevron, an
/// optional subtitle): that shape is for list-style option sheets, this one
/// is for a screen's overflow menu, where every row navigates away (hence the
/// chevron) except the last destructive one, which hides it.
class SheetMenuRow extends StatelessWidget {
  const SheetMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;

  /// Already localized.
  final String label;

  final VoidCallback onTap;

  /// Overrides the icon and label color; used by the destructive "Eliminar"
  /// row, which wears the semantic `expense` family.
  final Color? foreground;

  /// `false` hides the trailing chevron — the destructive row does not
  /// navigate anywhere, so it carries none (`sFSH9` disabled in `g57hEW`).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final tint = foreground ?? colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
