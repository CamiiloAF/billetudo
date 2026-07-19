import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// A selectable row of the `Sheet - Filtro de Etiqueta` (`FL1gK`, node
/// `WjelV`): a circular "#" wrap (never a Lucide icon — the literal
/// character), the tag name, and a check mark that only appears once
/// selected.
class TagFilterRow extends StatelessWidget {
  const TagFilterRow({
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? colors.primarySoft : colors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colors.primaryOnSoft
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: selected
                    ? Icon(
                        LucideIcons.check,
                        size: 20,
                        color: colors.primaryOnSoft,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
