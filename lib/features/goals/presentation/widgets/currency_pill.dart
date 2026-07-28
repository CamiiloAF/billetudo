import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Currency chip shown at the end of the "Objetivo" amount row (`Ed7Lz`
/// Currency Locked / `H8HDGn` Currency): a `$muted` pill with the code and,
/// locked (an account is linked) a padlock, or unlocked a chevron-down to
/// switch currency.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({required this.label, required this.locked, this.onTap, super.key});

  final String label;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(locked ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(locked ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: locked ? 7 : 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                locked ? LucideIcons.lock : LucideIcons.chevronDown,
                size: locked ? 13 : 14,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
