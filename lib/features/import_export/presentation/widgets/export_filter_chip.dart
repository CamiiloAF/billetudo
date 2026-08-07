import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One pill of the export "Filtros de transacciones" section (`zFLrC`'s
/// `Chip Cuenta`/`Chip Categoria`/`Chip Tipo`/`Chip Etiqueta`): white/bordered
/// at rest, switching to `$sky-soft`/`$sky` when active — this feature's own
/// export accent, never `$primary` (reserved to "nube" everywhere in
/// Import/Export, `design-system/billetudo/pages/import-export.md`
/// §Nomenclatura), unlike the `primary`-tinted chip Transacciones' filter bar
/// uses.
class ExportFilterChip extends StatelessWidget {
  const ExportFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.leadingIcon,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  /// `false` renders the same non-interactive treatment "Section Filtros"
  /// gets when "Transacciones" is off (`h6ZQQw`).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground = active ? colors.sky : colors.textSecondary;

    return Material(
      color: active ? colors.skySoft : colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? colors.sky : colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon case final icon?) ...[
                      Icon(icon, size: 14, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 14, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
