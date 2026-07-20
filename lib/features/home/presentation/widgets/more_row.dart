import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'coming_soon_badge.dart';

/// A single row of the "Más" hub: icon + label, with an optional secondary
/// description line, optionally flagged as "Próximamente".
///
/// Pencil's `Appearance Field` (`gXcHt`'s Cuentas/Categorías/Deudas/
/// Recurrentes/Importar y exportar/Ajustes rows) pairs the bold title
/// (`IwyuZ`) with a secondary description line (`RK3zo`). "Cerrar sesión"
/// (`AL4y1`) is a different pattern in the same frame — icon + label only,
/// no sublabel — so [description] stays nullable rather than required.
class MoreRow extends StatelessWidget {
  const MoreRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
    this.comingSoon = false,
    super.key,
  });

  final IconData icon;
  final String label;

  /// The secondary line under [label] (e.g. "Gestiona tus cuentas y
  /// saldos"). `null` renders a single-line row, matching "Cerrar sesión".
  final String? description;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    // Pencil's `Icon Wrap` (`r6Zlx` on `R8PlN`) is a full
                    // circle: `cornerRadius` 22 on a 44x44 box, not
                    // `radiusMedium` (16) on 40x40. That extra 4px of icon
                    // width and 2px of gap below were part of why longer
                    // titles ("Gráficas e informes", "Importar y exportar")
                    // had less room than Pencil budgets for them.
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, size: 20, color: colors.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pencil's `Title Row` (`els07`) pairs `Label`
                      // (`IwyuZ`) with the `Coming Soon Badge` in a
                      // horizontal row; only the title shares width with
                      // the badge, not the sublabel below.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // Row labels in `Mas — Final` reuse
                              // `Appearance Field`'s `Label` (`IwyuZ`): 600,
                              // not the baseline 500.
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (comingSoon) ...[
                            const SizedBox(width: 8),
                            ComingSoonBadge(label: l10n.comingSoonBadge),
                          ],
                        ],
                      ),
                      if (description case final description?) ...[
                        const SizedBox(height: 2),
                        // `Appearance Field`'s `Sublabel` (`RK3zo`): 12/500,
                        // `text-secondary`, full width below the title row.
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // No fixed gap here: Pencil's row is `justifyContent:
                // space_between` with a hugging left group, so the gap
                // before the chevron is whatever space remains, not a
                // reserved minimum. A fixed `SizedBox` here ate into the
                // title's available width for no reason in the design.
                Icon(
                  LucideIcons.chevronRight,
                  // Pencil's `Chevron` (`y16jpI`) is 20x20; the default
                  // `Icon` size (24) quietly took 4 extra px away from the
                  // title.
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
