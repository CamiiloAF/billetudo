import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Currency badge shown under a goal's hero amount field: locked (with a
/// padlock) once an account is linked, or tappable to switch currency.
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
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(LucideIcons.lock, size: 12, color: colors.primaryOnSoftStrong),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primaryOnSoftStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!locked) ...[
                const SizedBox(width: 5),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: colors.primaryOnSoftStrong,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
