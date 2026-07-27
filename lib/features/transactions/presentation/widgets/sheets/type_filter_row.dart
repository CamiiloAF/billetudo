import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/transaction.dart';

/// A row of the `Filtrar por tipo` sheet (`rjjfw`/`haoOi`): the "fila
/// completa" selection pattern (no dedicated checkbox — the whole row
/// switches to `primary-soft`/`primary` when selected, revealing a `check`
/// in a fixed 24x24 slot on the right), with the type's own icon inline.
class TypeFilterRow extends StatelessWidget {
  const TypeFilterRow({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final TransactionType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? colors.primarySoft : colors.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(type),
                    size: 18,
                    color:
                        selected ? colors.primaryOnSoft : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          size: 18,
                          color: colors.primaryOnSoft,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(TransactionType type) => switch (type) {
        TransactionType.expense => LucideIcons.trendingDown,
        TransactionType.income => LucideIcons.trendingUp,
        TransactionType.transfer => LucideIcons.arrowLeftRight,
      };
}
