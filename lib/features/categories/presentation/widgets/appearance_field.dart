import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/category_appearance.dart';

/// The `Appearance Field` component (`categorias.md`): icon-wrap 44x44 +
/// label/sublabel + chevron. Replaces 4 near-identical manual copies across
/// the create/edit forms.
class AppearanceField extends StatelessWidget {
  const AppearanceField({
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.iconName,
    this.colorToken,
    this.colorLocked = false,
    super.key,
  });

  /// Already localized. "Icono y color".
  final String label;

  /// "Toca para cambiar" (has a value) vs. "Toca para elegir (opcional)"
  /// (empty state, `sparkles`).
  final String sublabel;

  final String? iconName;
  final String? colorToken;

  /// Subcategory only (`R8PlN`/`N04bc`): shows a small lock icon inline
  /// between the swatch and the label (no background/border, matches
  /// Pencil's `Left Group` layout). The row stays fully tappable — only the
  /// color grid inside the picker sheet is disabled, the icon grid is not.
  final bool colorLocked;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final hasValue = iconName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasValue
                    ? CategoryAppearance.softColorFor(colors, colorToken)
                    : colors.muted,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                CategoryAppearance.iconFor(iconName),
                color: hasValue
                    ? CategoryAppearance.colorFor(colors, colorToken)
                    : colors.textSecondary,
              ),
            ),
            if (colorLocked) ...[
              const SizedBox(width: 10),
              Icon(LucideIcons.lock, size: 13, color: colors.textSecondary),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
