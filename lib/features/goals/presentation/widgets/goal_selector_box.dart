import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Tappable, dropdown-styled box for optional goal fields (account, target
/// date) that show a placeholder hint when unset and a clear ("x") action
/// once a value is picked.
class GoalSelectorBox extends StatelessWidget {
  const GoalSelectorBox({
    required this.icon,
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
    this.onClear,
    super.key,
  });

  final IconData icon;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final value = this.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText == null ? colors.border : colors.expense,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value == null
                          ? colors.textSecondary
                          : colors.textPrimary,
                    ),
                  ),
                ),
                if (onClear case final onClear? when value != null)
                  InkResponse(
                    onTap: onClear,
                    radius: 18,
                    child: Icon(LucideIcons.x, size: 16, color: colors.textSecondary),
                  )
                else
                  // `wOlOA`'s `PrXDA` is overridden to `chevron-right` for
                  // every compact list-style row Metas uses it for (Cuenta,
                  // Fecha) — never the dropdown `chevron-down`.
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.expense),
          ),
        ],
      ],
    );
  }
}
