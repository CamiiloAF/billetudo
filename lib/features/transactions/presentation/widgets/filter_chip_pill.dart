import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One pill of the `Movimientos` filter row (`B3GGa`/`xAk6Y`): neutral by
/// default, switching to the `primary-soft`/`primary` treatment the instant
/// its own dimension has an active filter — the same rule for all five chips
/// (cuenta, categoría, tipo, fecha, etiqueta).
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// 14px, e.g. the selected account's type icon.
  final IconData? leadingIcon;

  /// 14px, e.g. the account chip's `chevron-down`.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground =
        active ? colors.primaryOnSoftStrong : colors.textSecondary;

    return Material(
      color: active ? colors.primarySoft : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: active ? colors.primary : colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: active ? 13 : 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 14, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
