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
    super.key,
  });

  /// Already localized. "Icono y color".
  final String label;

  /// "Toca para cambiar" (has a value) vs. "Toca para elegir (opcional)"
  /// (empty state, `sparkles`).
  final String sublabel;

  final String? iconName;
  final String? colorToken;

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
